require 'rails_helper'

RSpec.describe Recurrence::PhoneCreditPostpaid::Create, type: :model do
  let(:provider) { create(:phone_credit_provider) }
  let(:provider_prefix) { build(:provider_prefix, provider_id: provider.id) }

  let(:push_notif_url) { "#{Channel::Config::TELOLET_URL}/_internal/publishers/push-notifications" }
  let(:onsite_notif_url) { "#{Channel::Config::TELOLET_URL}/_internal/publishers/onsite" }

  let(:recursive_url) { "#{Channel::Config::RECURSIVE_ENDPOINT}/_internal/templates" }
  let(:recursive_response) { { data: { id: 1 } }.to_json }

  let(:params) {
    {
      buyer_id: 1,
      amount: 0,
      recurrence_value: 11,
      recurrence_type: 'on_date',
      payment_method: 'deposit',
      action_date: nil,
      customer_number: '6281234000001',
      customer_name: 'SEPULSA'
    }
  }
  let(:form) { instance_double(Form::Recurrence::PhoneCreditPostpaid, params) }

  describe '#run!' do
    subject { Recurrence::PhoneCreditPostpaid::Create.new(form) }

    context 'with valid params' do
      before do
        allow(Toggles::OnSiteNotif).to receive(:active?) { true }
        allow(Toggles::PushNotif).to receive(:active?) { true }
        stub_request(:post, recursive_url).to_return(status: 201, body: recursive_response)
        stub_request(:post, push_notif_url).to_return(status: 200, body: { status: 'OK' }.to_json)
        stub_request(:post, onsite_notif_url).to_return(status: 200, body: { status: 'OK' }.to_json)
      end

      let(:test_obj) { subject.run!.attributes.deep_symbolize_keys }
      let(:expected_result) { 
        params.slice(:buyer_id, :customer_name).merge(recursive_id: 1, customer_number: 6281234000001) 
      }
      it { expect{subject.run!}.not_to raise_error }
      it { expect(test_obj).to include expected_result }
    end

    context 'when request to recursive failed' do
      before { stub_request(:post, recursive_url).to_raise(RestClient::Exception.new('Connection timeout')) }

      it { expect{subject.run!}.to raise_error }
    end
  end
end
