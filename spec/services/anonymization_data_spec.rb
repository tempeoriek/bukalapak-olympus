# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Services::AnonymizationData, type: :model do
  let(:buyer_id) { '123' }
  let(:random) { 'some-random-string' }
  let(:electricity_transaction) { build_stubbed(:postpaid_transaction_with_bill) }
  let(:electricity_recurrence) { build_stubbed(:electricity_postpaid_recurrence_template_detail) }
  let(:pdam_transaction) { build_stubbed(:pdam_transaction_with_bill) }
  let(:pdam_recurrence) { build_stubbed(:pdam_recurrence_template_detail) }
  let(:bpjs_ketenagakerjaan_transaction) { build_stubbed(:bpjs_ketenagakerjaan_transaction) }
  let(:credit_card_transaction) { build_stubbed(:cc_transaction) }
  let(:provider) { build_stubbed(:phone_credit_provider) }
  let(:phone_credit_transaction) { build_stubbed(:phone_credit_postpaid_transaction) }
  let(:phone_credit_recurrence) { build_stubbed(:phone_credit_postpaid_recurrence_template_detail) }
  let(:bpjs_kesehatan_transaction) { build_stubbed(:bpjs_kesehatan_transaction) }
  let(:bpjs_kesehatan_recurrence) { build_stubbed(:bpjs_kesehatan_recurrence_template_detail) }
  let(:family_member) { build_stubbed(:bpjs_kesehatan_family_member) }
  let(:deleted_user) { "DeletedUser-#{random}"}

  subject { described_class.new(buyer_id).perform }

  before { allow(SecureRandom).to receive(:uuid).and_return(random) }

  describe 'O2OVPE-2375: #perform' do
    context 'with all products' do
      before do
        # electricity postpaid
        electricity_transaction_mock = double
        allow(::PostpaidTransaction).to receive(:where).with(buyer_id: buyer_id).and_return(electricity_transaction_mock)
        allow(electricity_transaction_mock).to receive(:find_each).and_yield(electricity_transaction)
        allow(electricity_transaction).to receive(:update_columns).with({"customer_name" => deleted_user}).and_return(true)
        electricity_recurrence_mock = double
        allow(::ElectricityPostpaidRecurrenceTemplateDetail).to receive(:where).with(buyer_id: buyer_id).and_return(electricity_recurrence_mock)
        allow(electricity_recurrence_mock).to receive(:find_each).and_yield(electricity_recurrence)
        allow(electricity_recurrence).to receive(:update_columns).with({"customer_name" => deleted_user}).and_return(true)

        # # pdam
        pdam_transaction_mock = double
        allow(::PdamTransaction).to receive(:where).with(buyer_id: buyer_id).and_return(pdam_transaction_mock)
        allow(pdam_transaction_mock).to receive(:find_each).and_yield(pdam_transaction)
        allow(pdam_transaction).to receive(:update_columns)
          .with({"customer_name" => deleted_user, "address" => deleted_user})  
          .and_return(true)
        pdam_recurrence_mock = double
        allow(::PdamRecurrenceTemplateDetail).to receive(:where).with(buyer_id: buyer_id).and_return(pdam_recurrence_mock)
        allow(pdam_recurrence_mock).to receive(:find_each).and_yield(pdam_recurrence)
        allow(pdam_recurrence).to receive(:update_columns).with({"customer_name" => deleted_user}).and_return(true)

        # # bpjs ketenagakerjaan
        bpjs_ketenagakerjaan_transaction_mock = double
        allow(::BpjsKetenagakerjaanTransaction).to receive(:where).with(buyer_id: buyer_id).and_return(bpjs_ketenagakerjaan_transaction_mock)
        allow(bpjs_ketenagakerjaan_transaction_mock).to receive(:find_each).and_yield(bpjs_ketenagakerjaan_transaction)
        allow(bpjs_ketenagakerjaan_transaction).to receive(:update_columns)
          .with({"customer_number" => deleted_user, "customer_name" => deleted_user})  
          .and_return(true)

        # # credit card bills
        credit_card_transaction_mock = double
        allow(::CreditCardBillTransaction).to receive(:where).with(buyer_id: buyer_id).and_return(credit_card_transaction_mock)
        allow(credit_card_transaction_mock).to receive(:find_each).and_yield(credit_card_transaction)
        allow(credit_card_transaction).to receive(:update_columns)
          .with({"customer_name" => deleted_user, "customer_number" => deleted_user})  
          .and_return(true)

        # # phone credit postpaid
        allow(PhoneCreditProvider).to receive(:find).and_return(provider)
        phone_credit_transaction_mock = double
        allow(::PhoneCreditPostpaidTransaction).to receive(:where).with(buyer_id: buyer_id).and_return(phone_credit_transaction_mock)
        allow(phone_credit_transaction_mock).to receive(:find_each).and_yield(phone_credit_transaction)
        allow(phone_credit_transaction).to receive(:update_columns)
          .with({"customer_name" => deleted_user, "phone_number" => deleted_user})  
          .and_return(true)
        phone_credit_recurrence_mock = double
        allow(::PhoneCreditPostpaidRecurrenceTemplateDetail).to receive(:where).with(buyer_id: buyer_id).and_return(phone_credit_recurrence_mock)
        allow(phone_credit_recurrence_mock).to receive(:find_each).and_yield(phone_credit_recurrence)
        allow(phone_credit_recurrence).to receive(:update_columns)
          .with({"customer_name" => deleted_user, "customer_number" => deleted_user})  
          .and_return(true)

        # # bpjs kesehatan
        bpjs_kesehatan_transaction_mock = double
        allow(::BpjsKesehatanTransaction).to receive(:where).with(buyer_id: buyer_id).and_return(bpjs_kesehatan_transaction_mock)
        allow(bpjs_kesehatan_transaction_mock).to receive(:find_each).and_yield(bpjs_kesehatan_transaction)
        allow(bpjs_kesehatan_transaction_mock).to receive(:pluck).and_return([bpjs_kesehatan_transaction.id])
        allow(bpjs_kesehatan_transaction).to receive(:update_columns)
          .with({"customer_name" => deleted_user, "customer_number" => deleted_user, "phone_number" => deleted_user})  
          .and_return(true)
        bpjs_kesehatan_recurrence_mock = double
        allow(::BpjsKesehatanRecurrenceTemplateDetail).to receive(:where).with(buyer_id: buyer_id).and_return(bpjs_kesehatan_recurrence_mock)
        allow(bpjs_kesehatan_recurrence_mock).to receive(:find_each).and_yield(bpjs_kesehatan_recurrence) 
        allow(bpjs_kesehatan_recurrence).to receive(:update_columns)
          .with({"customer_name" => deleted_user, "customer_number" => deleted_user, "phone_number" => deleted_user})  
          .and_return(true)
        family_member_mock = double
        allow(::BpjsKesehatanFamilyMember).to receive(:where).with(bpjs_kesehatan_transaction_id: [bpjs_kesehatan_transaction.id]).and_return(family_member_mock)
        allow(family_member_mock).to receive(:find_each).and_yield(family_member)
        allow(family_member).to receive(:update_columns)
          .with({name: deleted_user, member_number: deleted_user})  
          .and_return(true)
      end

      it 'anonymizations works properly' do
        expect{ subject }.not_to raise_error
      end
    end

    context 'when error' do
      before do
        electricity_transaction_mock = double
        allow(::PostpaidTransaction).to receive(:where).with(buyer_id: buyer_id).and_return(electricity_transaction_mock)
        allow(electricity_transaction_mock).to receive(:find_each).and_yield(electricity_transaction)
        allow(electricity_transaction).to receive(:update_columns).with({"customer_name" => deleted_user}).and_raise(StandardError)
      end

      it 'raise an error' do
        expect(Logger2).to receive(:error).once
        expect{ subject }.to raise_error(StandardError)
      end
    end
  end
end
