require 'rails_helper'

RSpec.describe BpjsKetenagakerjaanTransaction, type: :model do
  let(:transaction) { build_stubbed(:bpjs_ketenagakerjaan_transaction, :bpu) }
  let(:expected_transaction_type) { 'bpjs-ketenagakerjaan' }
  let(:recurrent_transaction) { build_stubbed(:bpjs_ketenagakerjaan_transaction, :recurrent) }
  let(:expected_image_url) { 'https://s4.bukalapak.com/images/virtual_product/logo_bpjs_tk.jpg' }
  let(:expected_partner_name) { 'ayoconnect' }
  let(:expected_partner_hash) do
    {
      name: 'PT. Ayopop Teknologi Indonesia'
    }
  end

  let(:expected_period) do
    {
      total_month: subject.payment_period.present? ? subject.payment_period.to_i : nil,
      start_date: subject.start_bill_period,
      end_date: subject.end_bill_period
    }
  end

  let(:expected_period_unpaid_bills) do
    {
      total_month: nil,
      start_date: subject.start_bill_period,
      end_date: subject.end_bill_period
    }
  end

  let(:expected_bills) do
    subject.bpjs_ketenagakerjaan_bills&.map do |bill|
      {
        jht: bill.jht,
        jkk: bill.jkk,
        jkm: bill.jkm,
        jkp: bill.jkp,
        jp: bill.jp,
        amount: bill.amount
      }.compact
    end
  end

  let(:expected_db_customer_name) { 'NICO JULIAN' }
  let(:expected_unpaid_bills) { false }

  def expected_json_value(masked = false)
    {
      'id' => subject.id,
      'buyer_id' => subject.buyer_id,
      'invoice_id' => 1,
      'remote_transaction_id' => 1,
      'state' => 'pending',
      'amount' => 14_000,
      'admin_charge' => 1500,
      'customer_number' => '187101090793000901',
      'customer_name' => masked ? 'NI*O JU***N' : 'NICO JULIAN',
      'branch_name' => 'JAKARTA GROGOL',
      'reference_number' => nil,
      'partner' => expected_partner_hash,
      'type' => expected_transaction_type,
      'image_url' => expected_image_url,
      'transaction_type' => 'agent',
      'processed_at' => nil,
      'succeeded_at' => nil,
      'failed_at' => nil,
      'bpjs_tk_type' => 'bpu',
      'bill_code' => '921083112662',
      'npp' => nil,
      'division' => nil,
      'bills' => expected_bills,
      'period' => expected_period,
      'unpaid_bills' => expected_unpaid_bills
    }
  end

  subject { transaction }

  describe '.product_type' do
    it { expect(subject.product_type).to eq(expected_transaction_type) }
  end

  describe '.image_url' do
    it { expect(subject.image_url).to eq(expected_image_url) }
  end

  describe '.partner_name' do
    it { expect(subject.partner_name).to eq(expected_partner_name) }
  end

  describe '.partner_hash' do
    it { expect(subject.partner_hash).to eq(expected_partner_hash) }
  end

  describe 'O2OVPD-1497: .period' do
    context 'without unpaid bills' do
      it { expect(subject.period).to eq(expected_period) }
    end

    context 'with unpaid bills' do
      let(:transaction) { build_stubbed(:bpjs_ketenagakerjaan_transaction, :bpu, unpaid_bills: true, payment_period: 1) }

      it { expect(subject.period).to eq(expected_period_unpaid_bills) }
    end
  end

  describe '.bills' do
    it { expect(subject.bills).to eq(expected_bills) }
  end

  describe 'customer_name' do
    it { expect(subject.customer_name).to eq(expected_db_customer_name) }
  end

  describe 'O2OVPD-1497: .as_json' do
    context 'without unpaid bills' do
      context 'when masked' do
        it 'returns the correct json' do
          expect(subject.as_json({ masked: true })).to eq(expected_json_value(masked: true))
        end
      end

      context 'when not masked' do
        it 'returns the correct json' do
          expect(subject.as_json).to eq(expected_json_value)
        end
      end
    end

    context 'with unpaid bills' do
      let(:transaction) { build_stubbed(:bpjs_ketenagakerjaan_transaction, :bpu, unpaid_bills: true, payment_period: nil) }
      let(:expected_unpaid_bills) { true }

      context 'when masked' do
        it 'returns the correct json' do
          expect(subject.as_json({ masked: true })).to eq(expected_json_value(masked: true))
        end
      end

      context 'when not masked' do
        it 'returns the correct json' do
          expect(subject.as_json).to eq(expected_json_value)
        end
      end
    end
  end

  describe 'O2OVPD-884: .recurrent?' do
    context 'when recurring transaction' do
      it 'returns true' do
        expect(recurrent_transaction.recurrent?).to eq true
      end
    end

    context 'when not recurring transaction' do
      it 'returns false' do
        expect(subject.recurrent?).to eq false
      end
    end
  end

  describe 'O2OVPE-750: #biller_product' do
    it 'returns correct value' do
      expect(transaction.biller_product).to eq nil
    end
  end
end
