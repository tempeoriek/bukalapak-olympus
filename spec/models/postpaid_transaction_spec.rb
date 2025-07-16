require "rails_helper"
require 'support/transaction_state_machine_mocks'

RSpec.describe PostpaidTransaction, type: :model do
  include_context 'transaction_state_machine_mocks'

  let(:transaction) { build_stubbed(:postpaid_transaction_with_bill) }
  let(:recurrent_transaction) { build_stubbed(:postpaid_transaction_with_bill, :recurrent) }
  let(:mass_bill_transaction) { build_stubbed(:postpaid_transaction_with_bill, :with_mass_bill)}
  let(:expected_order_id) { "#{ELECTRICITY_POSTPAID_PREFIX}-1"}
  let(:expected_transaction_type) { "electricity_postpaid" }
  let(:expected_partner_hash) {
    {
      name: PARTNER_OFFICIAL_NAME[transaction.partner]
    }
  }
  let(:expected_as_json) {
    {
      'id' => transaction.id,
      'buyer_id' => transaction.buyer_id,
      'invoice_id' => transaction.invoice_id,
      'remote_transaction_id' => transaction.remote_transaction_id,
      'reference_number' => transaction.reference_number,
      'customer_number' => transaction.customer_number,
      'customer_name' => transaction.customer_name,
      'stand_meter' => transaction.stand_meter,
      'segmentation' => transaction.segmentation,
      'power' => transaction.power,
      'outstanding_bill' => transaction.outstanding_bill,
      'unpaid_bill' => transaction.unpaid_bill,
      'penalty_fee' => transaction.penalty_fee,
      'admin_charge' => transaction.admin_charge,
      'amount' => transaction.amount,
      'state' => transaction.state,
      'info_text' => transaction.info_text,
      'processed_at' => transaction.processed_at,
      'succeeded_at' => transaction.succeeded_at,
      'failed_at' => transaction.failed_at,
      'period' => transaction.period,
      'mass_bill_id' => transaction.mass_bill_id,
      'bills' => [{
        'bill_period' => transaction.bills[0][:bill_period],
        'penalty_fee' => transaction.bills[0][:penalty_fee],
        'amount' => transaction.bills[0][:amount]
      }],
      'partner_name' => transaction.partner,
      'partner' => transaction.partner_hash,
      'type' => expected_transaction_type,
      'image_url' => transaction.image_url,
      'transaction_type' => transaction.transaction_type
    }
  }

  describe 'validation' do
    it { expect(transaction.valid?).to eq true}
  end

  describe '.period' do
    it { expect(transaction).to respond_to(:bills) }
    it { expect{ transaction.bills[0] }.not_to raise_error }
  end

  describe '.order_id' do
    it { expect(transaction.order_id).to eq (expected_order_id) }
  end

  describe '.product_type' do
    it { expect(transaction.product_type).to eq (expected_transaction_type) }
  end

  describe '.partner_hash' do
    it { expect(transaction.partner_hash).to eq (expected_partner_hash) }
  end

  describe '.partner_object' do
    it 'does not raise error' do
      expect(ElectricityPostpaidPartner).to receive(:find_by).with(name: transaction.partner).and_return true
      expect { transaction.partner_object }.not_to raise_error
    end
  end

  describe '.bill_period' do
    it 'not raise error' do
      expect{ transaction.bill_period }.not_to raise_error
    end
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

  describe ".period" do
    it "should have same count with bills" do
      periods = transaction.period
      bills = transaction.bills
      expect(periods.length).to eq(bills.length)
    end
  end

  describe '.as_json' do
    it { expect(transaction.as_json).to eq (expected_as_json) }
  end

  describe '.is_mitra_transaction_type?' do
    it 'not raise error' do
      expect(transaction.is_mitra?).to be false
    end

    context 'with transaction_type agent' do
      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :agent) }
      it {
        expect(transaction.mitra_transaction_type?).to be_truthy
      }
    end
  end

  describe '.is_bukaconnect_transaction_type?' do
    it 'not raise error' do
      expect(transaction.is_mitra?).to be false
    end

    context 'with transaction_type agent' do
      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :collecting_agent) }
      it {
        expect(transaction.bukaconnect_transaction_type?).to be_truthy
      }
    end
  end

  describe '#is_mitra?' do
    before do
      allow(ElectricityPostpaidPartner).to receive(:find_by).with(name: transaction.partner).and_return(partner_object)
    end

    context 'when transaction_type agent and partner is not bukaconnect' do
      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :agent, :partner_tektaya) }
      let(:partner_object) { build(:electricity_postpaid_partner, :ayoconnect) }

      it 'returns true' do
        expect(transaction.is_mitra?).to be true
      end
    end

    context 'when transaction_type bukaconnect and partner is not bukaconnect' do
      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :collecting_agent, :partner_tektaya) }
      let(:partner_object) { build(:electricity_postpaid_partner, :ayoconnect) }

      it 'returns true' do
        expect(transaction.is_mitra?).to be true
      end
    end
  end

  describe '#is_bukaconnect?' do
    before do
      allow(ElectricityPostpaidPartner).to receive(:find_by).with(name: transaction.partner).and_return(partner_object)
    end

    context 'when transaction_type bukaconnect and partner is not bukaconnect' do
      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :agent, :partner_tektaya) }
      let(:partner_object) { build(:electricity_postpaid_partner, :ayoconnect) }

      it 'returns true' do
        expect(transaction.is_bukaconnect?).to be false
      end
    end

    context 'when transaction_type bukaconnect and partner is bukaconnect' do
      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, :collecting_agent, :partner_tektaya) }
      let(:partner_object) { build(:electricity_postpaid_partner, :sepulsa_bukaconnect) }

      it 'returns true' do
        expect(transaction.is_bukaconnect?).to be true
      end
    end
  end

  describe '.response_code' do
    before {
      expect(RedisOlympus).to receive(:get).and_return(return_code)
    }
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
    before {
      expect(RedisOlympus).to receive(:get).and_return(return_code)
    }
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

  describe '.middleman_details' do
    let(:expected_keys) {
      [ :reference_number, :customer_number, :customer_name, :segmentation, :power, :stand_meter, :outstanding_bill, :unpaid_bill, :period, :penalty_fee, :amount, :admin_charge, :bills, :info_text ]
    }

    it 'returns hash with expected keys' do
      expected_keys.each do | key |
        expect(transaction.middleman_details).to have_key(key)
      end
    end
  end

  describe 'O2OVPE-271: #mass_bill_id' do
    context 'when mass bill transaction' do
      it 'returns mass_bill_id' do
        expect(mass_bill_transaction.mass_bill_id).to eq mass_bill_transaction.electricity_postpaid_mass_bill.mass_bill_id
      end
    end

    context 'when not mass bill transaction' do
      it 'returns nil' do
        expect(transaction.mass_bill_id).to eq nil
      end
    end
  end

  describe 'O2OVPE-750: #biller_product' do
    it 'returns correct value' do
      expect(transaction.biller_product).to eq nil
    end
  end
end
