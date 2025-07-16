require 'rails_helper'

RSpec.describe Exclusive::Transaction::BpjsKesehatanController, type: :controller do

  describe 'GET #show' do
    let(:transaction) { build(:bpjs_kesehatan_transaction) }

    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
      allow(BpjsKesehatanTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'not authorized' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'normal'} })
      end

      it 'returns 401' do
        get :show, params: { id: 1 }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
        expect(response.status).to eq(401)
      end
    end

    context 'transaction not present' do
      it 'returns transaction not found' do
        allow(transaction).to receive(:present?).and_return(false)
        get :show, params: { id: 1 }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18108)
        expect(response.status).to eq(404)
      end
    end

    context 'transaction present' do
      before do
        allow(transaction).to receive(:present?).and_return(true)
        allow(BpjsKesehatanTransaction).to receive(:find_by_id).and_return(transaction)
      end

      it 'returns http success' do
        get :show, params: { id: 1 }
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'POST #confirm' do
    let(:transaction) { build(:bpjs_kesehatan_transaction) }

    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
      allow(BpjsKesehatanTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'not authorized' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'normal'} })
      end

      it 'returns 401' do
        post :confirm, params: { id: 1 }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
        expect(response.status).to eq(401)
      end
    end

    context 'invalid parameters' do
      it 'raise invalid param errors' do
        allow(transaction).to receive(:present?).and_return(false)
        post :confirm, params: { some_dleif: 123 }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18131)
        expect(response.status).to eq(422)
      end
    end

    context 'transaction not present' do
      it 'returns transaction not found' do
        allow(transaction).to receive(:present?).and_return(false)
        post :confirm, params: { id: 1 }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18108)
        expect(response.status).to eq(404)
      end
    end

    context 'transaction present' do
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

  describe 'GET #show_by_customer_number' do
    let(:transactions) { build_list(:bpjs_kesehatan_transaction, 2) }

    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
      allow(BpjsKesehatanTransaction).to receive_message_chain(:where, :count).and_return(2)
      allow(BpjsKesehatanTransaction).to receive_message_chain(:where, :order, :limit, :offset).and_return(transactions)
    end

    context 'not authorized' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'normal'} })
      end

      it 'returns 401' do
        get :show_by_customer_number, params: { customer_numbers: ['08112345678'].to_s }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
        expect(response.status).to eq(401)
      end
    end

    context 'customer number not given / empty' do
      it 'returns empty' do
        expect(BpjsKesehatanTransaction).not_to receive(:where)
        get :show_by_customer_number
        expect(JSON.parse(response.body)["data"]).to eq([])
        expect(response.status).to eq(200)

        expect(BpjsKesehatanTransaction).not_to receive(:where)
        get :show_by_customer_number, params: { customer_numbers: nil }
        expect(JSON.parse(response.body)["data"]).to eq([])
        expect(response.status).to eq(200)
      end
    end

    context 'transaction not present' do
      before do
        allow(BpjsKesehatanTransaction).to receive_message_chain(:where, :count).and_return(0)
        allow(BpjsKesehatanTransaction).to receive_message_chain(:where, :order, :limit, :offset).and_return([])
      end

      it 'returns empty' do
        get :show_by_customer_number, params: { customer_numbers: ['08112345678'].to_s }
        expect(JSON.parse(response.body)["data"]).to eq([])
        expect(JSON.parse(response.body)["meta"]["total"]).to eq(0)
        expect(response.status).to eq(200)
      end
    end

    context 'transaction present' do
      before do
        allow(BpjsKesehatanTransaction).to receive_message_chain(:where, :count).and_return(2)
        allow(BpjsKesehatanTransaction).to receive_message_chain(:where, :order, :limit, :offset).and_return(transactions)
      end

      it 'returns http success' do
        get :show_by_customer_number, params: { customer_numbers: ['08112345678'].to_s, limit: 100.to_s }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["meta"]["total"]).to eq(2)
        expect(JSON.parse(response.body)["meta"]["limit"]).to eq(100)
      end
    end
  end
end
