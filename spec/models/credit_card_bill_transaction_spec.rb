require "rails_helper"
require 'support/transaction_state_machine_mocks'

RSpec.describe CreditCardBillTransaction, type: :model do
  include_context 'transaction_state_machine_mocks'

  let(:cc_biller) { create(:credit_card_biller, :bni, :partner_bni) }
  let(:insuffice_amount) { build_stubbed(:cc_transaction, :bill_insufficient) }
  let(:insuffice_amount_and_low) { build_stubbed(:cc_transaction, :bill_insufficient, :low_min_payment) }
  let(:expected_order_id) { "#{CREDIT_CARD_BILL_PREFIX}-1"}
  let(:expected_transaction_type) { CREDIT_CARD_BILL_PRODUCT }
  let(:expected_admin_charge) { 0 }
  let(:expected_bill_period) { "Oktober 2012" }
  let(:expected_card_number) { '5289190005449145' }
  let(:expected_state_changed_at) {
    {
      processed_at: subject.processed_at,
      succeeded_at: subject.succeeded_at,
      failed_at: subject.failed_at
    }
   }
   let(:expected_partner_hash) {
     {
       name: PARTNER_OFFICIAL_NAME[subject.partner.name]
     }
    }
  let(:expected_masked_customer_name) { 'SumXXXXXXXHiu' }

  let(:expected_json_value) {
    {
      'id' => subject.id,
      'buyer_id' => subject.buyer_id,
      'invoice_id' => 1,
      'remote_transaction_id' => 1,
      'state' => 'succeeded',
      'customer_number' => '4665-73XX-XXXX-0117',
      'customer_name' => expected_masked_customer_name,
      'statement_date' => subject.statement_date,
      'due_date' => subject.due_date,
      'amount' => 2000000,
      'minimum_payment' => 2000000,
      'transaction_type' => 'user',
      'admin_charge' => 0,
      'state_changed_at' => subject.state_changed_at,
      'partner' => subject.partner_hash,
      'biller' => {
        id: subject.biller.id,
        name: subject.biller.name,
        image_url: subject.biller.image_url
      },
      'type' => CREDIT_CARD_BILL_PRODUCT
    }
  }

  subject { build(:cc_transaction, :succeeded, credit_card_biller: cc_biller, credit_card_bill_partner: cc_biller.partner) }

  before do
    allow_any_instance_of(CreditCardBillTransaction).to receive(:credit_card_biller).and_return(cc_biller)
  end

  describe 'transaction state' do
    it 'has defined states enum' do
      states = [
        'pending',
        'processed',
        'succeeded',
        'failed',
        'paid',
        'partner_succeeded',
        'partner_failed',
        'expired',
        'cancelled'
      ]

      expect(described_class.states.keys).to include(*states)
    end
  end

  describe 'transaction type' do
    it 'has defined transaction type enum' do
      transaction_types = [
        'user',
        'agent',
        'procurement',
        'collecting_agent'
      ]

      expect(described_class.transaction_types.keys).to include(*transaction_types)
    end
  end

  describe 'validation' do
    it { expect(subject.valid?).to eq (true) }
  end

  describe '.order_id' do
    it { expect(subject.order_id).to eq (expected_order_id) }
  end

  describe '.product_type' do
    it { expect(subject.product_type).to eq (expected_transaction_type) }
  end


  describe '.admin_charge' do
    it { expect(subject.admin_charge).to eq (expected_admin_charge) }
  end

  describe '.state_changed_at' do
    it { expect(subject.state_changed_at).to eq (expected_state_changed_at) }
  end

  describe '.bill_period' do
    it { expect(subject.bill_period).to eq (expected_bill_period) }
  end

  describe '.partner_hash' do
    it { expect(subject.partner_hash).to eq (expected_partner_hash) }
  end

  describe '.partner' do
    it { expect(subject).to respond_to(:credit_card_bill_partner) }
  end

  describe '.biller' do
    it { expect(subject).to respond_to(:credit_card_biller) }
  end

  describe '.recurrent?' do
    it { expect(subject.recurrent?).to eq (false) }
  end

  describe '.as_json' do
    it 'returns the correct json' do
      expect(subject.as_json).to eq(expected_json_value)
    end
  end

  describe '#masked_customer_name' do
    context 'when no customer name' do
      subject { build(:cc_transaction, :succeeded, credit_card_biller: cc_biller, credit_card_bill_partner: cc_biller.partner, customer_name: nil) }
      it 'returns dash' do
        expect(subject.masked_customer_name).to eq '-'
      end
    end

    context 'when customer_name exist' do
      it 'returns masked customer name' do
        expect(subject.masked_customer_name).to eq expected_masked_customer_name
      end
    end
  end

  describe '.set_card_number' do
    it 'not raise error' do
      expect { subject.set_card_number }.not_to raise_error
    end
    it 'run save!' do
      expect_any_instance_of(CreditCardBillTransaction).to receive(:save!).and_return(true)
      subject.set_card_number
    end
  end

  describe '.card_number' do
    it 'not raise error' do
      expect {subject.card_number}.not_to raise_error
    end
    it 'should return' do
      expect(subject.card_number).to eq (expected_card_number)
    end

    context 'when cimb niaga thor as a partner' do
      let(:cc_biller) { create(:credit_card_biller, :cimbniaga_thor, :partner_cimbniaga_thor) }

      context 'card already masking' do
        let(:expected_masking_card_number) { '4665-73XX-XXXX-0117' }
        subject { build(:cc_transaction, :succeeded, credit_card_biller: cc_biller, credit_card_bill_partner: cc_biller.partner) }

        it 'return masked customer_number' do
          expect(subject.card_number).to eq expected_masking_card_number
        end
      end
      context 'card not masking yet' do
        let(:expected_masking_card_number) { '4665-46XX-XXXX-1111' }
        subject { build(:cc_transaction, :paid_thor, credit_card_biller: cc_biller, credit_card_bill_partner: cc_biller.partner) }

        it 'return masked customer_number' do
          expect(subject.card_number).to eq expected_masking_card_number
        end
      end
    end
  end

  describe '.generate_key' do
    it 'not raise error' do
     expect { subject.generate_key }.not_to raise_error
    end
  end

  describe '.validate_amount' do
    context 'insufficient amount' do
      it 'raise error' do
        expect { insuffice_amount.validate_amount }.to raise_error(Exceptions::InsufficientAmount)
      end
    end

    context 'insufficient amount and low minimum payment' do
      it 'raise error' do
        expect { insuffice_amount_and_low.validate_amount }.to raise_error(Exceptions::InsufficientAmount)
      end
    end

    context 'non bni' do
      let(:insuffice_amount) { build_stubbed(:cc_transaction, :bill_insufficient, :visa, amount: 9999, bukalapak_admin_charge: 0, partner_admin_charge: 0) }
      it 'raise error' do
        expect { insuffice_amount.validate_amount }.to raise_error(Exceptions::InsufficientAmount)
      end
    end
  end

  describe '#as_json' do
    it {
      expect(subject.as_json).to include(
        "id",
        "customer_name",
        "customer_number",
        "statement_date",
        "due_date",
        "amount",
        "minimum_payment",
        "state",
        "transaction_type",
        "remote_transaction_id",
        "invoice_id",
        "admin_charge",
        "state_changed_at",
        "partner",
        "biller",
        "type"
      )
    }
    it 'subject.as_json["state_changed_at"]' do
      expect(subject.as_json["state_changed_at"]).to include(
        :processed_at, :succeeded_at, :failed_at
      )
    end
    it 'subject.as_json["partner"]' do
      expect(subject.as_json["partner"]).to include(:name)
    end
    it 'subject.as_json["biller"]' do
      expect(subject.as_json["biller"]).to include(
        :id, :name, :image_url
      )
    end
    it 'subject.as_json["type"] is credit-card-bill' do
      expect(subject.as_json["type"]).to eq 'credit-card-bill'
    end
    it 'customer_number is masked' do
      expect(subject.as_json['customer_number']).to include('X')
    end

    context 'with _options[:internal] = true' do
      it 'shows unmasked customer_number' do
        expect(subject.as_json(internal: true)['customer_number']).not_to include('X')
      end
    end

    context 'when collecting agent' do
      before do
        expect_any_instance_of(described_class).to receive(:middleman_response_code).and_return(50000)
        expect_any_instance_of(described_class).to receive(:middleman_failed_reason).and_return("#{cc_biller.partner.name}50000")
      end
      subject { build_stubbed(:cc_transaction, :succeeded, :collecting_agent, credit_card_biller: cc_biller, credit_card_bill_partner: cc_biller.partner) }

      it "has expected fields" do
        expect(subject.as_json).to include(
          "id",
          "customer_name",
          "customer_number",
          "statement_date",
          "due_date",
          "amount",
          "minimum_payment",
          "state",
          "transaction_type",
          "remote_transaction_id",
          "invoice_id",
          "admin_charge",
          "state_changed_at",
          "partner",
          "biller",
          "type",
          "response_code",
          "failed_reason"
        )
      end

      context 'when options internal true' do
        it 'shows masked customer_number' do
          expect(subject.as_json(internal: true)['customer_number']).to include('X')
        end
      end
    end

    context 'when partner is cimbniaga_thor' do
      let(:cc_biller) { create(:credit_card_biller, :cimbniaga_thor, :partner_cimbniaga_thor) }
      subject { build(:cc_transaction, :paid_thor, credit_card_biller: cc_biller, credit_card_bill_partner: cc_biller.partner) }

      context 'when options exclusive true' do
        let(:expected_card_number) { '4665-4665-4665-1111' }

        it 'should show unmasking card number' do
          expect(subject.as_json(exclusive: true)['customer_number']).to eq expected_card_number
        end
      end

      context 'when without options exclusive' do
        let(:expected_masking_card_number) { '4665-46XX-XXXX-1111' }

        it 'should show masking card number' do
          expect(subject.as_json['customer_number']).to eq expected_masking_card_number
        end
      end
    end
  end

  describe '.is_mitra?' do
    let(:cc_transaction) { build_stubbed(:cc_transaction) }
    it 'not raise error' do
      expect(cc_transaction.is_mitra?).to be false
    end

    context 'with transaction_type agent' do
      let(:cc_transaction) { build_stubbed(:cc_transaction, :agent) }
      it {
        expect(cc_transaction.is_mitra?).to be_truthy
      }
    end
  end

  describe '#partner_response_code' do
    context 'when partner is bni' do
      it { expect(subject.partner_response_code).to eq(subject.response_code) }
    end

    context 'when partner is pnl' do
      let(:cc_biller) { create(:credit_card_biller) }
      subject { build_stubbed(:cc_transaction, :succeeded, :collecting_agent, credit_card_biller: cc_biller, credit_card_bill_partner: cc_biller.partner) }

      before do
        expect_any_instance_of(described_class).to receive(
          :retrieve_partner_response
        ).with(
          subject.product_type,
          'callback',
          subject.partner_name,
          subject.remote_transaction_id
        ).and_return('CODE_FROM_PNL')
      end

      it { expect(subject.partner_response_code).to eq('CODE_FROM_PNL') }
    end

    # handle collided response code
    context 'when partner is visa' do
      let(:cc_biller) { create(:credit_card_biller, :visa, :partner_visa) }
      subject { build_stubbed(:cc_transaction, :succeeded, :collecting_agent, credit_card_biller: cc_biller, credit_card_bill_partner: cc_biller.partner) }

      context 'when response code is success' do
        subject { build_stubbed(:cc_transaction, :succeeded, :collecting_agent, credit_card_biller: cc_biller, credit_card_bill_partner: cc_biller.partner, response_code: 'success') }
        it { expect(subject.partner_response_code).to eq('VISA_00') }
      end

      context 'when response code is 5005' do
        subject { build_stubbed(:cc_transaction, :succeeded, :collecting_agent, credit_card_biller: cc_biller, credit_card_bill_partner: cc_biller.partner, response_code: '5005') }
        it { expect(subject.partner_response_code).to eq('VISA_12') }
      end

      context 'when response code is 5006' do
        subject { build_stubbed(:cc_transaction, :succeeded, :collecting_agent, credit_card_biller: cc_biller, credit_card_bill_partner: cc_biller.partner, response_code: '5006') }
        it { expect(subject.partner_response_code).to eq('VISA_13') }
      end
    end
  end

  describe '#middleman_response_code' do
    before do
      expect_any_instance_of(described_class).to receive(
        :retrieve_middleman_response_code
      ).with(
        subject.product_type,
        subject.partner_name,
        subject.partner_response_code
      ).and_return(50_000)
    end

    it { expect(subject.middleman_response_code).to eq(50_000) }
  end

  describe '#middleman_failed_reason' do
    before do
      expect_any_instance_of(described_class).to receive(
        :retrieve_middleman_failed_reason
      ).with(
        subject.partner_name,
        subject.partner_response_code
      ).and_return('bni|50000')
    end

    it { expect(subject.middleman_failed_reason).to eq('bni|50000') }
  end

  describe '#middleman_state' do
    context 'when state failed' do
      subject { build_stubbed(:cc_transaction, :failed) }
      it { expect(subject.middleman_state).to eq(:failed) }
    end

    context 'when state expired' do
      subject { build_stubbed(:cc_transaction, :expired) }
      it { expect(subject.middleman_state).to eq(:failed) }
    end

    context 'when state partner_failed' do
      subject { build_stubbed(:cc_transaction, :partner_failed) }
      it { expect(subject.middleman_state).to eq(:failed) }
    end

    context 'when state cancelled' do
      subject { build_stubbed(:cc_transaction, :cancelled) }
      it { expect(subject.middleman_state).to eq(:failed) }
    end

    context 'when state succeeded' do
      subject { build_stubbed(:cc_transaction, :succeeded) }
      it { expect(subject.middleman_state).to eq(:succeeded) }
    end

    context 'when state partner_succeeded' do
      subject { build_stubbed(:cc_transaction, :partner_succeeded) }
      it { expect(subject.middleman_state).to eq(:succeeded) }
    end

    context 'when state pending' do
      subject { build_stubbed(:cc_transaction, :pending) }
      it { expect(subject.middleman_state).to eq(:pending) }
    end

    context 'when state paid' do
      subject { build_stubbed(:cc_transaction, :paid) }
      it { expect(subject.middleman_state).to eq(:pending) }
    end

    context 'when state processed' do
      subject { build_stubbed(:cc_transaction, :processed) }
      it { expect(subject.middleman_state).to eq(:pending) }
    end
  end

  describe '#middleman_details' do
    let(:expected_middleman_details) do
      {
        customer_number:  subject.customer_number,
        customer_name:    expected_masked_customer_name,
        statement_date:   subject.statement_date,
        due_date:         subject.due_date,
        minimum_payment:  subject.minimum_payment,
        biller_name:      subject.biller.name,
        admin_charge:     subject.admin_charge
      }
    end

    it { expect(subject.middleman_details).to eq expected_middleman_details }
  end

  describe 'O2OVPE-750: #biller_product' do
    it 'returns correct value' do
      expect(subject.biller_product).to eq subject.biller.name
    end
  end
end
