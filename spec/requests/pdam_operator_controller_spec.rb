require 'rails_helper'

RSpec.describe Exclusive::PdamOperatorController, type: :controller do
  let(:pdam_operator) do
    create(:pdam_operator)
  end

  let(:header) do
    {
      'CONTENT_TYPE' => 'application/json'
    }
  end

  let(:expected_show_response) do
    JSON.parse({
      id: pdam_operator.id,
      name: 'Denpasar',
      code: 'pdam_denpasar',
      active: true,
      group: 'Bali',
      image_url: 'http://i0.kym-cdn.com/entries/icons/mobile/000/013/564/doge.jpg',
      partner: 'sepulsa',
      bukalapak_admin_charge: Test::BUKALAPAK_ADMIN_CHARGE,
      partner_admin_charge: Test::PARTNER_ADMIN_CHARGE,
      bill_day: 'every 20',
      due_day: 'every 1',
      terms_and_conditions: 'term and conditions',
      revenue: 1000,
      have_issue: false,
      update_selling_price: false
    }.to_json)
  end

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
      get :show, params: { id: pdam_operator.id }
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(200)
      hash_body = JSON.parse(response.body)
      expect(hash_body['data']).to match(expected_show_response)
    end
  end

  describe 'POST #create' do
    before do
      attrib = attributes_for(:pdam_operator)
      attrib['active'] = true
      attrib['partner'] = 'sepulsa'
      request.headers.merge!(header)
      post :create, params: attrib
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(201)
    end
  end

  describe 'O2OVPD-1358: #update' do
    let(:expected_update_response) do
      JSON.parse({
        id: pdam_operator.id,
        name: 'Banda Aceh',
        code: 'pdam_banda_aceh',
        active: true,
        group: 'Aceh',
        image_url: 'http://i0.kym-cdn.com/entries/icons/mobile/000/013/564/doge.jpg',
        partner: 'dji',
        bukalapak_admin_charge: Test::BUKALAPAK_ADMIN_CHARGE,
        partner_admin_charge: Test::PARTNER_ADMIN_CHARGE,
        bill_day: 'every 15',
        due_day: 'every 20',
        terms_and_conditions: 'term and conditions',
        revenue: 1500,
        have_issue: true,
        update_selling_price: false
      }.to_json)
    end

    before do
      attrib = pdam_operator.attributes
      attrib['partner'] = 'dji'
      attrib['name'] = 'Banda Aceh'
      attrib['code'] = 'pdam_banda_aceh'
      attrib['group'] = 'Aceh'
      attrib['active'] = true
      attrib['bill_day'] = 15
      attrib['due_day'] = 20
      attrib['revenue'] = 1500
      attrib['have_issue'] = true
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

  describe 'DELETE #delete' do
    before do
      delete :delete, params: { id: pdam_operator.id }
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(202)
      hash_body = JSON.parse(response.body)
      expect(hash_body['message']).to eq('Operator successfully deleted')
    end
  end
end
