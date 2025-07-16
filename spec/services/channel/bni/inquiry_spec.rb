require "rails_helper"
include PostpaidTransactionUtility

RSpec.describe Channel::BNI::CreditCardBill, :credit_card_bill, type: :model do

  subject { Channel::BNI::CreditCardBill.new(object) }

  before do
    allow(CreditCardBiller).to receive(:find).and_return credit_card_biller
    allow_any_instance_of(Redis).to receive(:get).and_return "token"
    expect(Toggles::WhitelistBni).to receive(:active?) { false }
    expect(Toggles::WhitelistVisa).to receive(:active?) { false }
    allow(Time).to receive(:now).and_return(Time.parse('12:00'))
  end

  describe 'inquiry_to_partner' do
    let(:object) { Form::CreditCardBill.new("4444333322221111", 1) }
    let (:non_bni_inquiry_response) {
      ResponseGeneralizer::CreditCardBill.new do |res|
        res.card_data = object.customer_number
        res.customer_number = "4444-33XX-XXXX-1111"
        res.biller = object.biller
        res.partner = object.biller.partner
        res.status = 'success'
        res.response_code = 'success'
      end
    }

    context 'BNI Biller' do
      let(:credit_card_biller) { create(:credit_card_biller, :bni, :partner_bni) }
      let(:bni_http_response) {{
        "error": false,
        "ket": "Credit Card BNI Inquiry",
        "cardNum": "4444333322221111",
        "statementDate": "11102012",
        "dueDate": "12102012",
        "cardHolder": "Sumartono Hiu",
        "cardlinkFlag": "02",
        "lastBillAmountSign": "+",
        "lastBillAmount": "261553126",
        "minPayment": "261553126",
        "minPayment1": "00000261",
        "minPayment2": "553126",
        "status": "2"
      }.to_json}
      let (:bni_inquiry_response) {
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

      before do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        allow(Channel::Connection::Http).to receive(:post).and_return bni_http_response
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code
        )).and_return(true)
      end

      it 'success inquiry' do
        expect(subject.inquiry_to_partner.attributes).to match bni_inquiry_response.attributes
      end

      context 'when cutoff time' do
        before { allow(Time).to receive(:now).and_return(Time.parse('17:00')) }

        it { expect{ subject.inquiry_to_partner }.to raise_error(Exceptions::ClosedTimeError) }
      end

      context 'when error' do
        before {
          allow(Channel::Connection::Http).to receive(:post).and_return error_response
        }
        context 'UnregisteredNumber' do
          let(:error_response) {{
            "error": true,
            "errorNum": "14",
            "message": "Nomor tidak terdaftar. (RC 14)"
          }.to_json}
          it { expect{ subject.inquiry_to_partner }.to raise_error(::Exceptions::UnregisteredNumber) }
        end
        context 'BillAlreadyPaid' do
          let(:error_response) {{
            "error": true,
            "errorNum": "5005",
            "message": "Tagihan sudah dibayar. (RC 5005)"
          }.to_json}
          it { expect{ subject.inquiry_to_partner }.to raise_error(::Exceptions::BillAlreadyPaid) }
        end
        context 'DefaultError' do
          let(:error_response) {{
            "error": true,
            "errorNum": "12",
            "message": "Transaksi tidak dapat dilakukan. (RC 12)"
          }.to_json}
          it { expect{ subject.inquiry_to_partner }.to raise_error(::Exceptions::DefaultError) }
        end
      end
    end

    context 'Non BNI Biller' do
      let(:credit_card_biller) { create(:credit_card_biller, :non_bni, :partner_bni) }

      before do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status, :response_code
        )).and_return(true)
      end

      it 'success inquiry' do
        expect(subject.inquiry_to_partner.attributes).to match non_bni_inquiry_response.attributes
      end

      context 'when cutoff time' do
        before { allow(Time).to receive(:now).and_return(Time.parse('17:00')) }

        it { expect{ subject.inquiry_to_partner }.to raise_error(Exceptions::ClosedTimeError) }
      end
    end
  end
end
