require 'rails_helper'

RSpec.describe Exclusive::Transaction::PhoneCreditController, type: :controller do

  describe 'GET #show' do
    let(:transaction) { build(:phone_credit_postpaid_transaction) }
    let(:provider) { build_stubbed(:phone_credit_provider) }

    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
      allow(PhoneCreditProvider).to receive(:find).and_return(provider)
      allow(PhoneCreditPostpaidTransaction).to receive(:find_by).and_return(transaction)
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
        allow(PhoneCreditPostpaidTransaction).to receive(:find_by_id).and_return(transaction)
        allow(PhoneCreditProvider).to receive(:find).and_return(provider)
      end

      it 'returns http success' do
        get :show, params: { id: 1 }
        expect(response.status).to eq(200)
      end
    end
  end
end
