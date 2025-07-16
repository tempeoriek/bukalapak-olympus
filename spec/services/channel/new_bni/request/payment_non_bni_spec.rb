# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Channel::NewBNI::Request::PaymentNonBNI, type: :model do
  describe '[REST-2542] payment with biller non BNI' do
    ACCOUNT_NUM = Channel::Config::NEW_BNI_ACCOUNT_NUM.freeze
    TRANSACTION_NON_BNI_URL = "#{Channel::Config::NEW_BNI_PAYMENT_NON_BNI_URL}".freeze
    API_KEY = Channel::Config::NEW_BNI_API_KEY

    subject { Channel::NewBNI::Request::PaymentNonBNI.new(transaction).perform }

    let(:cc_biller) { create(:credit_card_biller, :bni, :partner_bni) }
    let(:transaction) { create(:cc_transaction, :processed, credit_card_biller_id: cc_biller.id, credit_card_bill_partner_id: cc_biller.partner.id) }

    before do
      allow(CreditCardBiller).to receive(:find).and_return cc_biller
      allow(Keystore).to receive(:get).and_return("dummy_token")
      allow(Keystore).to receive(:expire).and_return(true)
      allow(Channel::Connection::Http).to receive(:post).and_return bni_http_response
    end

    context 'biller Non BNI succeed' do
      let(:response) {
        ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = SUCCESS
          res.response_code = BNI_SUCCESS
          res.partner_journal_number = "952271368"
          res.partner_financial_journal_number = "242856"
        end
      }
      let(:bni_http_response) {{
        "soapenv:Body": {
          "@xmlns:soapenc": "http://schemas.xmlsoap.org/soap/encoding/",
          "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
          "@xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
          "cr:paymentResponse": {
            "@xmlns:cr": "http://service.bni.co.id/creditcard",
            "response": {
              "clientId": "API",
              "reffNum": "20200915085102688404",
              "journal": "952271368",
              "financialJournal": "242856",
              "content": {
                "billingReff": nil,
                "fee": "0"
              }
            }
          }
        }
      }.to_json}

      it 'success payment' do
        expect(Channel::Connection::Http).to receive(:post).with(
          "#{TRANSACTION_NON_BNI_URL}?access_token=dummy_token",
          nil,
          {
            :accountNum => ACCOUNT_NUM,
            :amount => transaction.base_amount.to_s,
            :bankCode => transaction.biller.biller_code,
            :cardNum => transaction.card_number,
            :signature => anything
          },
          {:"X-API-Key" => API_KEY}).and_return bni_http_response

        expect(subject.attributes).to match response.attributes
      end
    end

    context 'biller Non BNI failed' do
      let(:response) {
        ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = FAILED
          res.response_code = "99"
        end
      }
      let(:bni_http_response) {{
        "soapenv:Body": {
          "soapenv:Fault": {
            "@xmlns:m": "http://service.bni.co.id/payment",
            "faultcode": "m:Fault",
            "faultstring": "Failed to establish a backside connection",
            "detail": {
              "@encodingStyle": "",
              "pa:Fault_element": {
                "@xmlns:pa": "http://service.bni.co.id/payment",
                "errorCode": "99",
                "errorDescription": "Failed to establish a backside connection"
              }
            }
          }
        }
      }.to_json}

      it 'failed payment' do
        expect(subject.attributes).to match response.attributes
      end
    end

    context 'when get response with timeout message' do
      let(:bni_http_response) {{
        "soapenv:Body": {
          "soapenv:Fault": {
            "@xmlns:m": "http://service.bni.co.id/payment",
            "faultcode": "m:Fault",
            "faultstring": "Failed to establish a backside connection",
            "detail": {
              "@encodingStyle": "",
              "pa:Fault_element": {
                "@xmlns:pa": "http://service.bni.co.id/payment",
                "errorCode": "0008",
                "errorDescription": "Failed to establish a backside connection"
              }
            }
          }
        }
      }.to_json}

      let (:response_pending) {
        ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = PENDING
          res.response_code = "timeout"
        end
      }

      it 'return response pending' do
        expect(subject.attributes).to match response_pending.attributes
      end
    end

    context 'when connection error' do
      let(:response) {
        ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = PENDING
          res.response_code = BNI_TIMEOUT
        end
      }
      let(:bni_http_response) { nil }
      it {
        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exception.new('Connection timeout'))
        expect(subject.attributes).to match response.attributes
      }
    end
  end
end
