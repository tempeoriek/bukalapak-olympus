# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Channel::NewBNI::Request::PaymentBNI, type: :model do
  describe '[REST-2541] payment with biller BNI' do
    ACCOUNT_NUM = Channel::Config::NEW_BNI_ACCOUNT_NUM.freeze
    TRANSACTION_URL = "#{Channel::Config::NEW_BNI_PAYMENT_BNI_URL}".freeze
    API_KEY = Channel::Config::NEW_BNI_API_KEY

    subject { Channel::NewBNI::Request::PaymentBNI.new(transaction).perform }

    let(:cc_biller) { create(:credit_card_biller, :bni, :partner_bni) }
    let(:transaction) { create(:cc_transaction, :processed, credit_card_biller_id: cc_biller.id, credit_card_bill_partner_id: cc_biller.partner.id) }

    before do
      allow(CreditCardBiller).to receive(:find).and_return cc_biller
      allow(Keystore).to receive(:get).and_return("dummy_token")
      allow(Keystore).to receive(:expire).and_return(true)
      allow(Channel::Connection::Http).to receive(:post).and_return bni_http_response
    end

    context 'biller BNI succeed' do
      let(:response) {
        ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = SUCCESS
          res.response_code = BNI_SUCCESS
          res.partner_journal_number = "946260235"
          res.partner_financial_journal_number = "065079"
        end
      }
      let(:bni_http_response) do
        {
          "NS1:body": {
            "sw:transactionResponse": {
              "@xmlns:cs": "http://test.co/switcher_v2/payment",
              "@xmlns:sw": "http://test.co.id/paymentlala",
              "response": {
                "@xmlns:ns_type": "http://test.co.id/paymentlala/payment",
                "clientId": "API",
                "reffNum": "20201211134720784634",
                "content": {
                  "@xsi:type": "pa_1:PayCreditCardRes",
                  "cardNum": {
                    "@xmlns:pa": "http://test.co.id/payment",
                    "@xmlns:pa_1": "http://test.co.id/paymentlala/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "4105040000001430"
                  },
                  "accountNum": {
                    "@xmlns:pa": "http://test.co.id/payment",
                    "@xmlns:pa_1": "http://test.co.id/paymentlala/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "0316031099"
                  },
                  "amount": {
                    "@xmlns:pa": "http://test.co.id/payment",
                    "@xmlns:pa_1": "http://test.co.id/paymentlala/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "100000"
                  },
                  "fee": "0"
                },
                "switcherJournal": "946260235",
                "financialJournal": "065079"
              }
            }
          }
        }.to_json
      end

      it 'success payment' do
        expect(Channel::Connection::Http).to receive(:post).with(
          "#{TRANSACTION_URL}?access_token=dummy_token",
          nil,
          {
            :accountNum => ACCOUNT_NUM,
            :amount => transaction.base_amount.to_s,
            :cardNum => transaction.card_number,
            :signature => anything
          },
          {:"X-API-Key" => API_KEY}).and_return bni_http_response

        expect(subject.attributes).to match response.attributes
      end
    end

    context 'biller BNI failed' do
      let(:response) {
        ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = FAILED
          res.response_code = "99"
        end
      }
      let(:bni_http_response) {{
        "soapenv:Body": {
          "soapenv:Fault": {
            "@xmlns:m": "http://test.co.id/payment",
            "faultcode": "m:Fault",
            "faultstring": "Failed to establish a backside connection",
            "detail": {
              "@encodingStyle": "",
              "pa:Fault_element": {
                "@xmlns:pa": "http://test.co.id/payment",
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
            "@xmlns:m": "http://test.co.id/payment",
            "faultcode": "m:Fault",
            "faultstring": "Failed to establish a backside connection",
            "detail": {
              "@encodingStyle": "",
              "pa:Fault_element": {
                "@xmlns:pa": "http://test.co.id/payment",
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
