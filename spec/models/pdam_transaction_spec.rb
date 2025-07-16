require "rails_helper"
require 'support/transaction_state_machine_mocks'

RSpec.describe PdamTransaction, type: :model do
  include_context 'transaction_state_machine_mocks'

  let(:pdam_operator) { build_stubbed(:pdam_operator) }
  let(:transaction) { build_stubbed(:pdam_transaction_with_bill) }
  let(:recurrent_transaction) { build_stubbed(:pdam_transaction_with_bill, :recurrent) }
  let(:expected_admin_charge) { 2 * (Test::ADMIN_CHARGE) }
  let(:expected_order_id) { "#{PDAM_PREFIX}-33"}
  let(:expected_transaction_type) { "pdam" }
  let(:expected_bill_period) { "#{I18n.l(Date.current.beginning_of_month - 1.month,  format: "%B %Y")} - #{I18n.l(Date.current.beginning_of_month,  format: "%B %Y")}" }
  let(:expected_period_length) { 2 }
  let(:expected_usage) { 2 }
  let(:expected_state_changed_at) {
    {
      processed_at: transaction.processed_at,
      succeeded_at: transaction.succeeded_at,
      failed_at: transaction.failed_at
    }
  }
  let(:expected_partner_hash) {
    {
      name: PARTNER_OFFICIAL_NAME[transaction.partner]
    }
  }
  let(:expected_start_end_usage_meter) {
    {
      start_usage_meter: transaction.pdam_bills.first.cubication&.split('-').first.to_i,
      end_usage_meter: transaction.pdam_bills.last.cubication&.split('-').last.to_i
    }
  }
  let(:expected_value_as_json) {
    {
      "id"=> transaction.id,
      "buyer_id"=> transaction.buyer_id,
      "customer_name"=> transaction.customer_name,
      "customer_number"=> transaction.customer_number,
      "start_bill_period"=> transaction.start_bill_period,
      "end_bill_period"=> transaction.end_bill_period,
      "amount"=> transaction.amount,
      "penalty_fee"=> transaction.penalty_fee,
      "state"=> transaction.state,
      "remote_transaction_id"=> transaction.remote_transaction_id,
      "invoice_id"=> transaction.invoice_id,
      "address"=> transaction.address,
      "usage"=> transaction.usage,
      "end_usage_meter" => transaction.start_end_usage_meter[:end_usage_meter],
      "start_usage_meter" => transaction.start_end_usage_meter[:start_usage_meter],
      "state_changed_at"=> transaction.state_changed_at,
      "admin_charge"=> transaction.admin_charge,
      "bills" => transaction.pdam_bills.as_json,
      "operator"=> transaction.operator.as_json,
      "partner"=> transaction.partner_hash,
      "type"=> expected_transaction_type,
      "transaction_type"=> transaction.transaction_type,
      "stand_meter"=> transaction.stand_meter,
      "segel"=> transaction.segel,
      "retribution"=> transaction.retribution,
      "reference_number"=> transaction.reference_number,
      "bills_period"=> transaction.bills_period
    }
  }
  let(:expected_CA_value_as_json) {
    {
      "id"=> transaction.id,
      "buyer_id"=> transaction.buyer_id,
      "customer_name"=> transaction.customer_name,
      "customer_number"=> transaction.customer_number,
      "start_bill_period"=> transaction.start_bill_period,
      "end_bill_period"=> transaction.end_bill_period,
      "amount"=> transaction.amount,
      "penalty_fee"=> transaction.penalty_fee,
      "state"=> transaction.state,
      "remote_transaction_id"=> transaction.remote_transaction_id,
      "invoice_id"=> transaction.invoice_id,
      "address"=> transaction.address,
      "usage"=> transaction.usage,
      "end_usage_meter" => transaction.start_end_usage_meter[:end_usage_meter],
      "start_usage_meter" => transaction.start_end_usage_meter[:start_usage_meter],
      "state_changed_at"=> transaction.state_changed_at,
      "admin_charge"=> transaction.admin_charge,
      "bills" => transaction.pdam_bills.as_json,
      "operator"=> transaction.operator.as_json,
      "partner"=> transaction.partner_hash,
      "type"=> expected_transaction_type,
      "transaction_type"=> transaction.transaction_type,
      "failed_reason": "sepulsa|50", 
      "response_code" => 50002,
      "stand_meter"=> transaction.stand_meter,
      "segel"=> transaction.segel,
      "retribution"=> transaction.retribution,
      "reference_number"=> transaction.reference_number,
      "bills_period"=> transaction.bills_period
    }
  }

  before do
    allow_any_instance_of(PdamTransaction).to receive(:pdam_operator).and_return(pdam_operator)
  end

  describe 'validation' do
    it { expect(transaction.valid?).to eq (true) }
  end

  describe '.order_id' do
    it { expect(transaction.order_id).to eq (expected_order_id) }
  end

  describe '.product_type' do
    it { expect(transaction.product_type).to eq (expected_transaction_type) }
  end

  describe 'operator' do
    it { expect(transaction).to respond_to(:pdam_operator) }
  end

  describe ".operator" do
    it { expect(transaction.operator).to eq(transaction.pdam_operator) }
  end

  describe ".period" do
    it "returns only 2 periods" do
      expect(transaction.period.length).to eq(expected_period_length)
    end

    it 'return the period expected' do
      expect(transaction.period).to eq([transaction.pdam_bills.first.bill_period, transaction.pdam_bills.last.bill_period])
    end
  end

  describe '.usage' do
    it { expect(transaction.usage).to eq (expected_usage) }
  end

  describe '.admin_charge' do
    it { expect(transaction.admin_charge).to eq (expected_admin_charge) }
  end

  describe '.state_changed_at' do
    it { expect(transaction.state_changed_at).to eq (expected_state_changed_at) }
  end

  describe '.partner_hash' do
    it { expect(transaction.partner_hash).to eq (expected_partner_hash) }
  end

  describe '.start_end_usage_meter' do
    it { expect(transaction.start_end_usage_meter).to eq (expected_start_end_usage_meter) }
  end

  describe '.bill_period' do
    it { expect(transaction.bill_period).to eq (expected_bill_period) }
  end

  describe '.recurrent?' do
    context 'when recurring transaction' do
      it 'returns true' do
        expect( recurrent_transaction.recurrent? ).to eq true
      end
    end

    context 'when not recurring transaction' do
      it 'returns false' do
        expect( transaction.recurrent?).to eq false
      end
    end
  end

  describe '#valid?' do
    let(:pdam_operator) { build_stubbed(:pdam_operator) }
    let(:attr) { attributes_for(:pdam_transaction_with_bill, pdam_operator_id: pdam_operator.id) }

    subject { described_class.new(attr) }

    context 'with valid admin_charge' do
      it { expect(subject.valid?).to be_truthy }
    end

    context 'with invalid admin_charge' do
      let(:attr) { attributes_for(:pdam_transaction_with_bill, pdam_operator_id: pdam_operator.id, bukalapak_admin_charge: 0) }
      it { expect(subject.valid?).to be_falsey }
    end
  end

  describe '.is_mitra?' do
    it 'not raise error' do
      expect(transaction.is_mitra?).to be false
    end

    context 'with transaction_type agent' do
      let(:transaction) { build_stubbed(:pdam_transaction_with_bill, :agent) }
      it {
        expect(transaction.is_mitra?).to be_truthy
      }
    end
  end

  describe '.response_code' do
    before { expect(RedisOlympus).to receive(:get).and_return(return_code) }
    subject { transaction.response_code }

    context 'known response_code' do
      let(:return_code) { MiddlemanResponseMapperUtility::SepulsaRC::BILL_ALREADY_PAID_OR_NOT_AVAILABLE }

      it { is_expected.to eq(50002) }
    end

    context 'unknown response_code' do
      let(:return_code) { 'unknown_code' }

      it { is_expected.to eq(50199) }
    end
  end

  describe '.failed_reason' do
    before { expect(RedisOlympus).to receive(:get).and_return(return_code) }
    subject { transaction.failed_reason }

    context 'known response_code' do
      let(:return_code) { MiddlemanResponseMapperUtility::SepulsaRC::BILL_ALREADY_PAID_OR_NOT_AVAILABLE }

      it { is_expected.to eq("sepulsa|50") }
    end

    context 'unknown response_code' do
      let(:return_code) { "unknown_code" }

      it { is_expected.to eq("sepulsa|unknown_code") }
    end
  end

  describe '.as_json' do
    context 'when transaction type is not collecting agent' do
      it 'returns the correct json' do
        expect(transaction.as_json.with_indifferent_access).to eq(expected_value_as_json.with_indifferent_access)
      end
    end

    context 'when transaction type is collecting agent' do
      before { allow(RedisOlympus).to receive(:get).and_return(return_code) }
      
      let(:return_code) { MiddlemanResponseMapperUtility::SepulsaRC::BILL_ALREADY_PAID_OR_NOT_AVAILABLE }
      let(:transaction) { build_stubbed(:pdam_transaction_with_bill, transaction_type: 'collecting_agent') }
      it 'returns the correct json' do
        expect(transaction.as_json.with_indifferent_access).to eq(expected_CA_value_as_json.with_indifferent_access)
      end
    end

    context 'with details of pdam transaction' do
      let(:details) do
        {
          bill_ref: 'something',
          tariff_classification_code: 'something'
        }
      end
      let(:transaction) { build_stubbed(:pdam_transaction_with_bill, details: details) }
      let(:expected_json) do
        result = expected_value_as_json

        result[:bill_ref] = 'something'
        result[:tariff_classification_code] = 'something'

        result
      end

      it 'returns the correct json' do
        expect(transaction.as_json.with_indifferent_access).to eq(expected_json.with_indifferent_access)
      end
    end

    context 'when details is nil' do
      let(:transaction) { build_stubbed(:pdam_transaction_with_bill, details: nil) }

      it 'returns the correct json' do
        expect(transaction.as_json.with_indifferent_access).to eq(expected_value_as_json.with_indifferent_access)
      end
    end
  end

  describe '#middleman_state' do
    context 'when state failed' do
      subject { build_stubbed(:pdam_transaction_with_bill, :failed) }
      it { expect(subject.middleman_state).to eq(:failed) }
    end

    context 'when state expired' do
      subject { build_stubbed(:pdam_transaction_with_bill, :expired) }
      it { expect(subject.middleman_state).to eq(:failed) }
    end

    context 'when state partner_failed' do
      subject { build_stubbed(:pdam_transaction_with_bill, :partner_failed) }
      it { expect(subject.middleman_state).to eq(:failed) }
    end

    context 'when state cancelled' do
      subject { build_stubbed(:pdam_transaction_with_bill, :cancelled) }
      it { 
        expect(subject.middleman_state).to eq(:failed) }
    end

    context 'when state succeeded' do
      subject { build_stubbed(:pdam_transaction_with_bill, :succeeded) }
      it { expect(subject.middleman_state).to eq(:succeeded) }
    end

    context 'when state partner_succeeded' do
      subject { build_stubbed(:pdam_transaction_with_bill, :partner_succeeded) }
      it { expect(subject.middleman_state).to eq(:succeeded) }
    end

    context 'when state pending' do
      subject { build_stubbed(:pdam_transaction_with_bill, :pending) }
      it { expect(subject.middleman_state).to eq(:pending) }
    end

    context 'when state paid' do
      subject { build_stubbed(:pdam_transaction_with_bill, :paid) }
      it { expect(subject.middleman_state).to eq(:pending) }
    end

    context 'when state processed' do
      subject { build_stubbed(:pdam_transaction_with_bill, :processed) }
      it { expect(subject.middleman_state).to eq(:pending) }
    end
  end

  describe '#middleman_details' do
    let(:expected_middleman_details) do
      {
        customer_number:      transaction.customer_number,
        customer_name:        transaction.customer_name,
        amount:               transaction.amount,
        admin_charge:         transaction.admin_charge,
        start_bill_period:    transaction.start_bill_period,
        end_bill_period:      transaction.end_bill_period,
        usage:                transaction.usage,
        address:              transaction.address,
        end_usage_meter:      transaction.start_end_usage_meter[:end_usage_meter],
        start_usage_meter:    transaction.start_end_usage_meter[:start_usage_meter],
        operator:             transaction.operator,
        bills:                transaction.pdam_bills.as_json,
      }
    end

    it { expect(transaction.middleman_details).to eq expected_middleman_details }
  end

  describe 'O2OVPE-750: #biller_product' do
    it 'returns correct value' do
      expect(transaction.biller_product).to eq transaction.operator.code
    end
  end
end
