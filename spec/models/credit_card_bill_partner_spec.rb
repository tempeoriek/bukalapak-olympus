require "rails_helper"

RSpec.describe CreditCardBillPartner, type: :model do
  let(:cc_biller) { build_stubbed(:credit_card_biller, :bni) }
  let(:cc_partner) { build(:credit_card_bill_partner, :pnl, credit_card_biller: cc_biller) }
  let(:expected_admin_charge) { 5000 }

  describe 'validation' do
    it { expect(cc_partner.valid?).to eq (true) }
  end

  describe '.admin_charge' do
    it { expect(cc_partner.admin_charge).to eq (expected_admin_charge) }
  end

  describe '.biller' do
    it { expect(cc_partner.biller).to eq (cc_biller) }
  end
end
