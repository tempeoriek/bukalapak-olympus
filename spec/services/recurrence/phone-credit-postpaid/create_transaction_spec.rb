require 'rails_helper'

RSpec.describe Recurrence::PhoneCreditPostpaid::CreateTransaction, type: :model do
  let(:provider) { create(:phone_credit_provider) }
  let(:provider_prefix) { build(:provider_prefix, provider_id: provider.id) }

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

  let(:template_id) { 1 }
  let(:template) { build(:phone_credit_postpaid_recurrence_template_detail) }

  let(:transaction) { create(:phone_credit_postpaid_transaction, :pending) }

  before do
    allow(ProviderPrefix).to receive(:find_by) { provider_prefix }
    allow(PhoneCreditProvider).to receive(:find) { provider }
  end

  describe '#run!' do
    subject { Recurrence::PhoneCreditPostpaid::CreateTransaction.new(template_id) }

    context 'with valid params' do
      before :each do
        allow_any_instance_of(Action::PhoneCreditTransaction::Create).to receive(:run!) { transaction }
        allow(::PhoneCreditPostpaidRecurrenceTemplateDetail).to receive(:find_by_id!) {template}
      end

      let(:test_obj) { subject.run!.attributes.deep_symbolize_keys }

      it { expect{subject.run!}.not_to raise_error }
      it { expect(test_obj[:template_detail_id]).to eq template_id }
    end

    context 'when request to recursive failed' do
      before :each do
        stub_request(:post, inquiry_url).to_raise(RestClient::Exception.new('Connection timeout'))
        allow(::PhoneCreditPostpaidRecurrenceTemplateDetail).to receive(:find_by_id!) {template}
      end

      it { expect{subject.run!}.to raise_error }
    end
  end
end
