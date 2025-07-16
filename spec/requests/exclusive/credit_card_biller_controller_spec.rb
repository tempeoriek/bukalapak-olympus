require "rails_helper"

RSpec.describe Exclusive::CreditCardBillerController, type: :controller do
  let(:cc_billers) { create_list(:credit_card_biller, 2, :bni, :partner_bni) }
  let(:cc_biller) { build(:credit_card_biller, :bni, :partner_bni) }
  let(:cc_transaction) { build_stubbed(:cc_transaction) }
  let(:cc_partner) { build(:credit_card_bill_partner, :bni) }
  let(:request_body) {
    {
      "id" => 2,
      "name" => "bni",
      "image_url" => "`https://s4.bukalapak.com/images/virtual_product/credit_card/bni.png`",
      "active" => true,
      "terms_and_conditions" => "Tagihan dibayar tiga hari sebelum jatuh tempo"
    }
  }

  let(:header) {
    {
      "CONTENT_TYPE" => "application/json"
    }
  }

  describe 'not authorize' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'user'} })
    end

    it 'should return http error (401)' do
      get :list
      expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
      expect(response.status).to eq(401)
    end
  end

  describe '#list' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
    end

    it 'should return https success' do
      expect(CreditCardBiller).to receive(:not_deleted).and_return(cc_billers)

      get :list
      expect(JSON.parse(response.body).count).to eq 2
      expect(response.status).to eq 200
    end
  end

  describe '#show' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
    end

    it 'should return BillerNotFound' do
      expect(CreditCardBiller).to receive_message_chain(:not_deleted, :find_by_id) { nil }
      get :show, params: { id: 1 }
      expect(response.status).to eq 404
    end

    it 'should return https success' do
      expect(CreditCardBiller).to receive_message_chain(:not_deleted, :find_by_id) { cc_biller }
      get :show, params: { id: 1 }
      expect(response.status).to eq 200
    end
  end

  describe '#create' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
      allow(::CreditCardBillPartner).to receive(:find_by).and_return(cc_partner)
    end

    it 'should return BillerNotFound' do
      # expect(request).to receive_message_chain(:body, :read) { create_params }
      request.headers.merge!(header)
      post :create, params: request_body
      expect(response.status).to eq 201
    end
  end

  describe '#update' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
    end

    it 'should return http success' do
      request.headers.merge!(header)
      expect(CreditCardBiller).to receive_message_chain(:not_deleted, :find) { cc_biller }

      put :update, params: request_body
      expect(response.status).to eq 200
    end
  end

  describe '#delete' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
      request.headers.merge!(header)
      expect(CreditCardBiller).to receive_message_chain(:not_deleted, :find) { cc_biller }
    end

    # let(:data) {instance_double(CreditCardBiller, )}

    it 'should return exception' do
      expect(CreditCardBillTransaction).to receive(:find_by) { cc_transaction }

      delete :delete, params: { id: 1 }
      expect(response.status).to eq 409

    end

    it 'should return http success' do
      expect(CreditCardBillTransaction).to receive(:find_by) { nil }

      delete :delete, params: { id: 1 }
      expect(response.status).to eq 202
    end
  end
end
