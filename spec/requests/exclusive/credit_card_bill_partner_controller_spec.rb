require "rails_helper"

RSpec.describe Exclusive::CreditCardBillPartnerController, type: :controller do
  let(:cc_biller) {create(:credit_card_biller, :partner_pnl, :bni)}
  let(:cc_partners) { create_list(:credit_card_bill_partner, 2, :bni) }
  let(:cc_partner) { build_stubbed(:credit_card_bill_partner, :bni) }
  let(:cc_transaction) { build_stubbed(:cc_transaction) }
  let(:create_and_update_request_body) {
    {
      "id" => 2,
      "name" => "bni",
      "terms_and_conditions" => "Bayar On-Time Yak!",
      "biller_code" => 'BNI',
      "bukalapak_admin_charge" => 1000,
      "partner_admin_charge" => 2000,
      "credit_card_biller_id" => cc_biller.id,
      "biller_id" => cc_biller.id,
      "active" => true,
      "revenue" => 1000,
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
      controller_methods = [
        # [ http_method, controller_method, params ]
        [:get, :show_biller_partners, {biller_id: 1}],
        [:get, :show_partners, {}],
        [:post, :create, {biller_id: 1}],
        [:put, :update, {biller_id: 1, id: 1}],
        [:delete, :delete, {biller_id: 1, id: 1}],
      ]

      controller_methods.each do | http_method, controller_method, params |
        send(http_method, controller_method, params: params)
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
        expect(response.status).to eq(401)
      end

    end
  end

  describe '#show_biller_partners' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
    end

    it 'should return https success' do
      expect(CreditCardBillPartner).to receive(:where).and_return(cc_biller.partners)

      get :show_biller_partners, params: {biller_id: cc_biller.id}

      json_result = JSON.parse(response.body)['data']

      expect(json_result.count).to eq cc_biller.partners.length
      expect(response.status).to eq 200
      expect(json_result[0]).to include('id', 'name', 'terms_and_conditions', 'biller_code', 'bukalapak_admin_charge', 'partner_admin_charge', 'active', 'revenue')
    end
  end

  describe '#show_partners' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
    end

    it 'should not raise error' do
      get :show_partners
      expect(response.status).to eq 200
    end
  end

  describe '#create' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
      allow(::CreditCardBiller).to receive(:find_by_id).and_return(cc_biller)
    end

    it 'should raise no error' do
      request.headers.merge!(header)
      expect_any_instance_of(Action::CreditCardBillPartner::Create).to receive(:run!).and_return( cc_partner )

      post :create, params: create_and_update_request_body
      expect(response.status).to eq 201
    end
  end

  describe '#update' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
      allow(::CreditCardBiller).to receive(:find_by_id).and_return(cc_biller)
    end

    it 'should return http success' do
      request.headers.merge!(header)
      expect(CreditCardBillPartner).to receive_message_chain(:not_deleted, :find_by_id).and_return( cc_partner )
      expect_any_instance_of(Action::CreditCardBillPartner::Update).to receive(:run!).and_return( cc_partner )

      put :update, params: create_and_update_request_body

      expect(response.status).to eq 200
    end
  end

  describe '#delete' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
      request.headers.merge!(header)
      expect(CreditCardBillPartner).to receive_message_chain(:not_deleted, :find_by_id).and_return( cc_partner )
    end

    # let(:data) {instance_double(CreditCardBiller, )}
    context 'when transaction created with partner exists' do
      it 'should not be successful' do
        expect(CreditCardBillTransaction).to receive(:find_by) { cc_transaction }

        delete :delete, params: { biller_id: cc_biller.id, id: cc_partner.id }
        expect(response.status).to eq 409
      end
    end

    context 'when no transaction created using this partner' do
      it 'should be successful' do
        expect(CreditCardBillTransaction).to receive(:find_by).and_return(nil)
        expect(cc_partner).to receive(:update_attributes!).with(hash_including(state: -1))

        delete :delete, params: { biller_id: cc_biller.id, id: cc_partner.id}
        expect(response.status).to eq 202
      end
    end
  end
end
