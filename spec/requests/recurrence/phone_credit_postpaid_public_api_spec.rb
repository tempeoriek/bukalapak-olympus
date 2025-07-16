# frozen_string_literal: true
require "rails_helper"

RSpec.describe Recurrence::PhoneCreditPostpaid::PublicController, type: :controller do
  let(:provider) { create(:phone_credit_provider) }
  let(:provider_prefix) { build(:provider_prefix, provider_id: provider.id) }

  let(:push_notif_url) { "#{Channel::Config::TELOLET_URL}/_internal/publishers/push-notifications" }
  let(:onsite_notif_url) { "#{Channel::Config::TELOLET_URL}/_internal/publishers/onsite" }

  let(:recursive_url) { "#{Channel::Config::RECURSIVE_ENDPOINT}/_internal/templates" }
  let(:recursive_response) { { data: { id: 1 } }.to_json }

  let(:inquiry_url) { "#{Channel::Config::SEPULSA_ENDPOINT}inquire.json" }
  let(:inquiry_response) {
    {
      'status': 'success',
      'reference_no': '2203267',
      'customer_no': '081234000001',
      'customer_name': 'SEPULSA',
      'response_code': '00',
      'bill_count': '1',
      'bill_periode': '201407',
      'bill_amount': '209294',
      'admin_fee': '2500',
      'total_amount': '211794'
    }.to_json
  }

  let(:params) {
    {
      'customer_number': '081234000001',
      'recurrence_type': 'month',
      'recurrence_value': '12'
    }
  }
  let(:template_json) {
    {
      id: PhoneCreditPostpaidRecurrenceTemplateDetail.last.id,
      customer_number: '081234000001',
      customer_name: 'SEPULSA',
      buyer_id: 1,
      recursive_id: 1,
      provider: {
        name: provider.provider,
        product_name: provider.product_name,
        logo_url: provider.logo_url
      }.as_json
    }.as_json
  }
  let(:create_response) {
    {
      data: template_json,
      meta: { http_status: 201 }
    }.as_json
  }
  let(:show_response) {
    {
      data: template_json,
      meta: { http_status: 200 }
    }.as_json
  }

  let(:decoded_token) {
    {
      resource_owner_id: 1,
      resource_owner: {
        role: 'normal',
        o2o_agent: {
          status: false
        }
      }
    }
  }

  describe 'POST /create' do
    context 'with valid request' do
      before do
        allow(ProviderPrefix).to receive(:find_by) { provider_prefix }
        allow(PhoneCreditProvider).to receive(:find) { provider }
        allow(JsonWebToken).to receive(:decode) { decoded_token }
        allow(Toggles::OnSiteNotif).to receive(:active?) { true }
        allow(Toggles::PushNotif).to receive(:active?) { true }
        stub_request(:post, inquiry_url).to_return(status: 200, body: inquiry_response)
        stub_request(:post, recursive_url).to_return(status: 201, body: recursive_response)
        stub_request(:post, push_notif_url).to_return(status: 200, body: { status: 'OK' }.to_json)
        stub_request(:post, onsite_notif_url).to_return(status: 200, body: { status: 'OK' }.to_json)

        post :create, params: params
      end

      it { expect(response.status).to eq 201 }
      it { expect(JSON.parse(response.body)).to eq create_response }
    end
  end

  describe 'GET /show' do
    context 'when account authrorized' do
      let(:template) { create(:phone_credit_postpaid_recurrence_template_detail) }
      before do
        allow(ProviderPrefix).to receive(:find_by) { provider_prefix }
        allow(PhoneCreditProvider).to receive(:find) { provider }
        allow(JsonWebToken).to receive(:decode) { decoded_token }
        get :show, params: { id: template.id }
      end

      it { expect(response.status).to eq 200 }
      it { expect(JSON.parse(response.body)).to eq show_response }
    end
  end
end
