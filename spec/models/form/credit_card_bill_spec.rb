require 'rails_helper'

RSpec.describe Form::CreditCardBill, type: :model do
  let(:customer_number){ CreditCardValidations::Factory.random }
  let(:customer_number_visa){ CreditCardValidations::Factory.random(:visa) }
  let(:biller_id){ 2 }
  let(:invalid_customer_number) { '341234567890123' }
  let(:invalid_cust_num_length) { '676185355603738373737' }
  let(:username) { 'acctest1' }

  let(:cur_biller) { double(::CreditCardBiller) }
  let(:cur_partner) { double(::CreditCardBillPartner) }

  before {
    allow(Toggles::WhitelistVisa).to receive(:active?) { false }
    allow(Toggles::WhitelistBni).to receive(:active?) { false }
  }

  it 'create new credit card bill form' do

    allow(cur_biller).to receive(:active?) { true }
    allow(cur_biller).to receive(:partner) { cur_partner }
    allow(cur_partner).to receive(:name) { 'pnl' }
    allow(::CreditCardBiller).to receive(:find) { cur_biller }
    allow(Toggles::WhitelistBni).to receive(:active?) { true }
    expect{Form::CreditCardBill.new(customer_number, biller_id)}.not_to raise_error
  end

  it 'raise error if biller not found' do

    allow(cur_biller).to receive(:active?) { false }
    allow(cur_biller).to receive(:partner) { cur_partner }
    allow(::CreditCardBiller).to receive(:find) { cur_biller }

    expect{Form::CreditCardBill.new(invalid_customer_number, biller_id)}.to raise_error ::Exceptions::BillerNotFound
  end

  it 'raise error if wrong customer number' do

    allow(cur_biller).to receive(:active?) { true }
    allow(cur_biller).to receive(:partner) { cur_partner }
    allow(::CreditCardBiller).to receive(:find) { cur_biller }

    expect{Form::CreditCardBill.new(invalid_customer_number, biller_id)}.to raise_error ::Exceptions::InvalidCreditCardNumberLength
  end

  it 'raise error if wrong customer number' do

    allow(cur_biller).to receive(:active?) { true }
    allow(cur_biller).to receive(:partner) { cur_partner }
    allow(::CreditCardBiller).to receive(:find) { cur_biller }

    expect{Form::CreditCardBill.new(invalid_cust_num_length, biller_id)}.to raise_error ::Exceptions::InvalidCreditCardNumberLength
  end

  context 'when whitelist_bni active'  do
    before do
      expect(CreditCardBiller).to receive(:find).with(biller_id) { biller }
      expect(Toggles::WhitelistBni).to receive(:active?) { true }
    end

    subject { described_class.new(customer_number, biller_id, username: username) }

    context 'with partner bni' do
      let(:biller) { create(:credit_card_biller, :bni, :partner_bni) }

      context 'when user whitelisted' do
        it { expect{ subject }.not_to raise_error }
      end

      context 'when user not whitelisted' do
        let(:username) { 'asd1234' }
        it { expect{ subject }.to raise_error(Exceptions::BillerUnavailable) }
      end
    end

    context 'with partner dbs' do
      let(:biller) { create(:credit_card_biller, :non_bni, :partner_pnl) }

      it { expect{ subject }.not_to raise_error }
    end
  end

  context 'when whitelist_visa active'  do
    before do
      expect(CreditCardBiller).to receive(:find).with(biller_id) { biller }
      expect(Toggles::WhitelistVisa).to receive(:active?) { true }
    end

    let(:username){ 'sliu' }

    subject { described_class.new(customer_number_visa, biller_id, username: username) }

    context 'with partner visa' do
      let(:biller) { create(:credit_card_biller, :visa, :partner_visa) }

      context 'when user whitelisted' do
        it { expect{ subject }.not_to raise_error }
      end

      context 'when user not whitelisted' do
        let(:username) { 'asd1234' }
        it { expect{ subject }.to raise_error(Exceptions::BillerUnavailable) }
      end
    end
  end

  context 'when biller partner is visa' do
    let(:biller) { create(:credit_card_biller, :visa, :partner_visa) }
    before {
      allow(cur_biller).to receive(:active?) { true }
      allow(cur_biller).to receive(:partner) { cur_partner }
      expect(CreditCardBiller).to receive(:find).with(biller_id) { biller }
    }

    it 'does not raise error if the card is a valid visa card' do
      expect{Form::CreditCardBill.new(CreditCardValidations::Factory.random(:visa), biller_id)}.not_to raise_error
    end

    it 'raise error if the card is not a valid visa card' do
      expect{Form::CreditCardBill.new(CreditCardValidations::Factory.random(:visa)+"12", biller_id)}.to raise_error ::Exceptions::InvalidCreditCardNumberLength
    end

  end
end
