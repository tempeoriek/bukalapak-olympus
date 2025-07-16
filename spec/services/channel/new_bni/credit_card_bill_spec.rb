# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Channel::NewBNI::CreditCardBill, type: :model do
  describe 'REST-2541: inquiry_to_partner' do
    before do
      allow(CreditCardBiller).to receive(:find).and_return credit_card_biller
      allow(::Toggles::WhitelistBni).to receive(:active?) { false }
      allow(::Toggles::WhitelistVisa).to receive(:active?) { false }
    end
    
    let(:object) { Form::CreditCardBill.new("4444333322221111", 1) }
    let(:credit_card_biller) { create(:credit_card_biller, :bni, :partner_bni) }
    let(:response) {
      ResponseGeneralizer::CreditCardBill.new do |res|
        res.card_data = object.customer_number
        res.customer_number = "4444-33XX-XXXX-1111"
        res.customer_name = "Sumartono Hiu"
        res.displayed_name = "Sumartono Hiu"
        res.statement_date = Date.new(2012, 10, 11)
        res.due_date = Date.new(2012, 10, 12)
        res.amount = 261553126
        res.minimum_payment = 261553126
        res.biller = object.biller
        res.partner = object.biller.partner
        res.status = 'success'
        res.response_code = 'success'
      end
    }

    subject { Channel::NewBNI::CreditCardBill.new(object).inquiry_to_partner }

    context 'when BNI inquiry' do
      it 'should return response correctly' do
        expect_any_instance_of(Channel::NewBNI::Request::Inquiry).to receive(:perform).and_return(response)
        expect(subject.attributes).to match response.attributes
      end
    end
  end

  describe '[REST-2542] #create_transaction' do
    let(:cc_biller) { create(:credit_card_biller, :non_bni, :partner_bni) }
    let(:transaction) { create(:cc_transaction, :processed, credit_card_biller_id: cc_biller.id, credit_card_bill_partner_id: cc_biller.partner.id) }
    let(:response) {
      ResponseGeneralizer::CreditCardBill.new do |res|
        res.status = SUCCESS
        res.response_code = BNI_SUCCESS
        res.partner_journal_number = "123456789   "
        res.partner_financial_journal_number = "123456"
      end
    }

    subject { Channel::NewBNI::CreditCardBill.new(transaction).create_transaction }

    context 'when the biller is not BNI' do
      it 'should return response correctly' do
        expect_any_instance_of(Channel::NewBNI::Request::PaymentNonBNI).to receive(:perform).and_return(response)
        expect(subject.attributes).to match response.attributes
      end
    end

    context 'when the biller is BNI' do
      let(:cc_biller) { create(:credit_card_biller, :bni, :partner_bni) }
      it 'should return response correctly' do
        expect_any_instance_of(Channel::NewBNI::Request::PaymentBNI).to receive(:perform).and_return(response)
        expect(subject.attributes).to match response.attributes
      end
    end
  end
end
