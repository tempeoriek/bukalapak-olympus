require "rails_helper"
require 'support/transaction_state_machine_mocks'

RSpec.describe PhoneCreditPostpaidTransaction, type: :model do
  include_context 'transaction_state_machine_mocks'

  let(:transaction) { build_stubbed(:phone_credit_postpaid_transaction) }
  let(:provider) { build_stubbed :phone_credit_provider }
  let(:expected_admin_charge) { 1500 }
  let(:expected_order_id) { "#{PHONE_CREDIT_POSTPAID_PREFIX}-30"}
  let(:expected_transaction_type) { "phone-credit-postpaid" }
  let(:expected_bill_period) { I18n.l(Date.parse(transaction.start_bill_period.to_s),  format: "%B %Y") }
  let(:expected_partner_hash) {
    {
      name: PARTNER_OFFICIAL_NAME[transaction.partner]
    }
  }
  let(:expected_as_json) {
    {
      'id' => transaction.id,
      'buyer_id' => transaction.buyer_id,
      'type' => Channel::Config::TRANSACTION_TYPE[PHONE_CREDIT_PRODUCT],
      'invoice_id' => transaction.invoice_id,
      'remote_transaction_id' => transaction.remote_transaction_id,
      'reference_no' => transaction.reference_number,
      'customer_name' => transaction.customer_name,
      'customer_number' => transaction.customer_number,
      'outstanding_bill' => transaction.outstanding_bill,
      'admin_charge' => 0,
      'penalty_fee' => 0,
      'amount' => transaction.total_amount,
      'start_bill_period' => transaction.start_bill_period,
      'end_bill_period' => transaction.end_bill_period,
      'state' => transaction.state,
      'partner' => transaction.partner_hash,
      'provider' => {
        name: transaction.provider.provider,
        product_name: transaction.provider.product_name,
        logo_url: transaction.provider.logo_url
      },
      'state_changed_at' => {
        processed_at: transaction.processed_at,
        succeeded_at: transaction.succeeded_at,
        failed_at: transaction.failed_at
      },
      'transaction_type' => transaction.transaction_type
    }
  }

  before do
    allow(PhoneCreditProvider).to receive(:find).and_return(provider)
  end

  describe 'validation' do
    it { expect(transaction.valid?).to eq (true) }
  end

  describe '.order_id' do
    it { expect(transaction.order_id).to eq (expected_order_id) }
  end

  describe '.customer_number' do
    it { expect(transaction).to respond_to(:phone_number) }
  end

  describe '.product_type' do
    it { expect(transaction.product_type).to eq (expected_transaction_type) }
  end

  describe '.partner_hash' do
    it { expect(transaction.partner_hash).to eq (expected_partner_hash) }
  end

  describe '.recurrent?' do
    it 'returns false' do
      expect( transaction.recurrent?).to eq false
    end
  end

  describe '.as_json' do
    it { expect(transaction.as_json).to eq (expected_as_json) }
  end

  describe 'provider' do
    it { expect(transaction.provider).to be_a_kind_of PhoneCreditProvider }    
  end

  describe '.admin_charge' do
    it { expect(transaction.admin_charge).to eq (expected_admin_charge) }
  end

  describe '.amount' do
    it { expect(transaction).to respond_to(:total_amount) }
  end

  describe '.bill_period' do
    it { expect(transaction.bill_period).to eq (expected_bill_period) }      
  end

  describe '.is_mitra?' do
    it 'not raise error' do
      expect(transaction.is_mitra?).to be false
    end
  end

  describe 'O2OVPE-750: #biller_product' do
    it 'returns correct value' do
      expect(transaction.biller_product).to eq provider.provider
    end
  end
end
