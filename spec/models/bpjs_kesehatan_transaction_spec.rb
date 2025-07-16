require 'rails_helper'
require 'support/transaction_state_machine_mocks'

RSpec.describe BpjsKesehatanTransaction, type: :model do
  include_context 'transaction_state_machine_mocks'

  let(:recurrent_transaction) { build_stubbed(:bpjs_kesehatan_transaction, :recurrent) }
  let(:expected_order_id) { "#{BPJS_KESEHATAN_PREFIX}-1"}
  let(:expected_transaction_type) { "bpjs-kesehatan" }
  let(:expected_admin_charge) { 1500 }

  let(:expected_json_value) {
    {
      'id' => subject.id,
      'buyer_id' => subject.buyer_id,
      'invoice_id' => 1,
      'remote_transaction_id' => 1,
      'state' => 'pending',
      'amount' => 51000,
      'admin_charge' => 1500,
      'customer_number' => '0000001430071801',
      'customer_name' => 'NISA KARTIKA INDIARTI',
      'family_member_count' => 1,
      'branch_name' => 'SEMARANG',
      'reference_number' => nil,
      'info' => nil,
      'partner' => {
        name: 'PT Sepulsa Teknologi Indonesia'
      },
      'payment_period' => '01',
      'paid_until' => {
        'month' => 9,
        'year' => 2017
      },
      'family_members' => subject.family_members.as_json,
      'type' => 'bpjs-kesehatan',
      'image_url' => 'https://s4.bukalapak.com/images/virtual_product/logo_bpjs.png',
      'transaction_type' => 'normal'
    }
  }

  subject { build_stubbed(:bpjs_kesehatan_transaction) }

  describe '.order_id' do
    it { expect(subject.order_id).to eq (expected_order_id) }
  end

  describe '.product_type' do
    it { expect(subject.product_type).to eq (expected_transaction_type) }
  end

  describe '.admin_charge' do
    it { expect(subject.admin_charge).to eq (expected_admin_charge) }
  end

  describe '.year' do
    it { expect(subject.year).to eq(2017) }
  end

  describe '.month' do
    it { expect(subject.month).to eq(9) }
  end

  describe '.family_members' do
    it { expect(subject).to respond_to(:family_members) }
  end

  describe '.partner_object' do
    it 'does not raise error' do
      expect(BpjsKesehatanPartner).to receive(:find_by).with(name: subject.partner).and_return true
      expect { subject.partner_object }.not_to raise_error
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
        expect( subject.recurrent?).to eq false
      end
    end
  end


  describe '.as_json' do
    it 'returns the correct json' do
      expect(subject.as_json).to eq(expected_json_value)
    end
  end

  describe '.is_mitra?' do
    let(:transaction) { build_stubbed(:bpjs_kesehatan_transaction) }
    it 'not raise error' do
      expect(transaction.is_mitra?).to be false
    end

    context 'with transaction_type agent' do
      let(:transaction) { build_stubbed(:bpjs_kesehatan_transaction, :agent) }
      it {
        expect(transaction.is_mitra?).to be_truthy
      }
    end
  end

  describe 'O2OVPE-750: #biller_product' do
    it 'returns correct value' do
      expect(recurrent_transaction.biller_product).to eq nil
    end
  end
end
