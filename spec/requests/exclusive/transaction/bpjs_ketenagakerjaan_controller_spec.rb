require 'rails_helper'

RSpec.describe Exclusive::Transaction::BpjsKetenagakerjaanController, type: :controller do
  let(:transaction) { build_stubbed(:bpjs_ketenagakerjaan_transaction) }

  before do
    allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: { agent: false, role: 'admin' } })
  end

  describe '#show' do
    before { allow(BpjsKetenagakerjaanTransaction).to receive(:find_by_id).and_return(transaction) }

    context 'when not authorized' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: { agent: false, role: 'normal' } })
      end

      it 'returns 401' do
        get :show, params: { id: 1 }
        expect(JSON.parse(response.body)['errors'][0]['code']).to eq(18_107)
        expect(response.status).to eq(401)
      end
    end

    context 'when transaction not present' do
      it 'returns transaction not found' do
        allow(transaction).to receive(:present?).and_return(false)
        get :show, params: { id: 1 }
        expect(JSON.parse(response.body)['errors'][0]['code']).to eq(18_108)
        expect(response.status).to eq(404)
      end
    end

    context 'when transaction present' do
      before { allow(transaction).to receive(:present?).and_return(true) }

      it 'returns http success' do
        get :show, params: { id: 1 }
        expect(response.status).to eq(200)
      end
    end
  end

  describe '#confirm' do
    before do
      allow(BpjsKetenagakerjaanTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'when not authorized' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: { agent: false, role: 'normal' } })
      end

      it 'returns 401' do
        post :confirm, params: { id: 1 }
        expect(JSON.parse(response.body)['errors'][0]['code']).to eq(18_107)
        expect(response.status).to eq(401)
      end
    end

    context 'with invalid parameters' do
      it 'raise invalid param errors' do
        allow(transaction).to receive(:present?).and_return(false)
        post :confirm, params: { some_param: 123 }
        expect(JSON.parse(response.body)['errors'][0]['code']).to eq(18_131)
        expect(response.status).to eq(422)
      end
    end

    context 'when transaction not present' do
      it 'returns transaction not found' do
        allow(transaction).to receive(:present?).and_return(false)
        post :confirm, params: { id: 1 }
        expect(JSON.parse(response.body)['errors'][0]['code']).to eq(18_108)
        expect(response.status).to eq(404)
      end
    end

    context 'when transaction present' do
      let(:mock_postpaid) { instance_double(Action::PostpaidTransaction::ManualConfirm) }

      before do
        allow(transaction).to receive(:present?).and_return(true)
        expect(Action::PostpaidTransaction::ManualConfirm).to receive(:new).with(transaction) { mock_postpaid }
        allow(mock_postpaid).to receive(:run!)
      end

      it 'returns http success' do
        post :confirm, params: { id: 1 }
        expect(response.status).to eq(200)
      end
    end
  end
end
