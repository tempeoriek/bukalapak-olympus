require "rails_helper"

RSpec.describe Exclusive::BpjsKesehatanPartnerController, type: :controller do
  let(:operator_id) { 1 }
  let(:bpjs_kesehatan_partner) {
    create(:bpjs_kesehatan_partner)
  }

  let(:header) {
    {
      "CONTENT_TYPE" => "application/json"
    }
  }

  let(:expected_show_response) {
    JSON.parse({
      id: bpjs_kesehatan_partner.id,
      name: 'sepulsa',
      bukalapak_admin_charge: 1000,
      partner_admin_charge: 500,
      state: 'active',
      revenue: 1000
    }.to_json)
  }

  before :all do
    described_class.skip_before_action :authorize!
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
  end


  describe 'GET #list' do
    before do
      get :list
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(200)
    end
  end

  describe 'GET #show' do
    before do
      get :show, params: { id: bpjs_kesehatan_partner.id }
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(200)
      hash_body = JSON.parse(response.body)
      expect(hash_body['data']).to match(expected_show_response)
    end
  end

  describe 'PUT #update' do
    let(:expected_update_response) {
      JSON.parse({
        id: bpjs_kesehatan_partner.id,
        name: 'sepulsa',
        state: 'active',
        bukalapak_admin_charge: 1000,
        partner_admin_charge: 2000,
        revenue: 1500
      }.to_json)
    }
    before do
      attrib = bpjs_kesehatan_partner.attributes
      attrib['bukalapak_admin_charge'] = 1000
      attrib['partner_admin_charge'] = 2000
      attrib['revenue'] = 1500
      request.headers.merge!(header)
      put :update, params: attrib
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(200)
      hash_body = JSON.parse(response.body)
      expect(hash_body['data']).to match(expected_update_response)
    end
  end
end
