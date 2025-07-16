require "rails_helper"

RSpec.describe Channel::NewBNI::Request::Inquiry, type: :model do
  INQUIRY_URL = "#{Channel::Config::NEW_BNI_INQUIRY_URL}".freeze
  API_KEY = Channel::Config::NEW_BNI_API_KEY

  subject { Channel::NewBNI::Request::Inquiry.new(object).perform }

  before do
    allow(CreditCardBiller).to receive(:find).and_return credit_card_biller
    allow(::Toggle::CreditCardBill::NewBNI).to receive(:active?) { true }
    allow(::Toggle::CreditCardBill::WhitelistNewBNI).to receive(:active?) { true }
    expect(::Toggles::WhitelistBni).to receive(:active?) { false }
    expect(::Toggles::WhitelistVisa).to receive(:active?) { false }
  end

  describe 'REST-2540, O2OVPD-120: inquiry_to_partner' do
    context 'with BNI credit card' do
      let(:object) { Form::CreditCardBill.new("4444333322221111", 1) }
      let(:credit_card_biller) { create(:credit_card_biller, :bni, :partner_bni) }
      let(:bni_inquiry_response) {
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
        allow_any_instance_of(Redis).to receive(:get).and_return "token"        
        allow(Time).to receive(:now).and_return(Time.parse('12:00'))
        allow(Channel::Connection::Http).to receive(:post).and_return bni_http_response
        allow(Keystore).to receive(:get).and_return("dummy_token")
        allow(Keystore).to receive(:expire).and_return(true)
      end

      context 'BNI Biller' do
        let(:bni_http_response) {{
          "NS1:body": {
            "sw:transactionResponse": {
              "@xmlns:cs": "http://service.bni.co.id/switcher_v2/payment",
              "@xmlns:sw": "http://service.bni.co.id/switcher_v2",
              "response": {
                "@xmlns:ns_type": "http://service.bni.co.id/switcher_v2/payment",
                "clientId": "API",
                "reffNum": "20201211124756296559",
                "content": {
                  "@xsi:type": "pa_1:InquiryCreditCardRes",
                  "cardNum": {
                    "@xmlns:pa": "http://service.bni.co.id/payment",
                    "@xmlns:pa_1": "http://service.bni.co.id/switcher_v2/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "4444333322221111"
                  },
                  "statementDate": {
                    "@xmlns:pa": "http://service.bni.co.id/payment",
                    "@xmlns:pa_1": "http://service.bni.co.id/switcher_v2/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "11102012"
                  },
                  "dueDate": {
                    "@xmlns:pa": "http://service.bni.co.id/payment",
                    "@xmlns:pa_1": "http://service.bni.co.id/switcher_v2/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "12102012"
                  },
                  "cardHolder": {
                    "@xmlns:pa": "http://service.bni.co.id/payment",
                    "@xmlns:pa_1": "http://service.bni.co.id/switcher_v2/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "Sumartono Hiu"
                  },
                  "cardlinkFlag": {
                    "@xmlns:pa": "http://service.bni.co.id/payment",
                    "@xmlns:pa_1": "http://service.bni.co.id/switcher_v2/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "02"
                  },
                  "lastBillAmountSign": {
                    "@xmlns:pa": "http://service.bni.co.id/payment",
                    "@xmlns:pa_1": "http://service.bni.co.id/switcher_v2/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "+"
                  },
                  "lastBillAmount": {
                    "@xmlns:pa": "http://service.bni.co.id/payment",
                    "@xmlns:pa_1": "http://service.bni.co.id/switcher_v2/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "261553126"
                  },
                  "minPayment": {
                    "@xmlns:pa": "http://service.bni.co.id/payment",
                    "@xmlns:pa_1": "http://service.bni.co.id/switcher_v2/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "261553126"
                  },
                  "minPayment1": {
                    "@xmlns:pa": "http://service.bni.co.id/payment",
                    "@xmlns:pa_1": "http://service.bni.co.id/switcher_v2/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "00000261"
                  },
                  "minPayment2": {
                    "@xmlns:pa": "http://service.bni.co.id/payment",
                    "@xmlns:pa_1": "http://service.bni.co.id/switcher_v2/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "553126"
                  },
                  "status": {
                    "@xmlns:pa": "http://service.bni.co.id/payment",
                    "@xmlns:pa_1": "http://service.bni.co.id/switcher_v2/payment",
                    "@xmlns:soapenv": "http://schemas.xmlsoap.org/soap/envelope/",
                    "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
                    "#text": "2"
                  }
                }
              }
            }
          }
        }.to_json}
  
        it 'success inquiry' do
          expect(Channel::Connection::Http).to receive(:post).with(
            "#{INQUIRY_URL}?access_token=dummy_token",
            nil,
            {
              :cardNum => object.customer_number,
              :signature => anything
            },
            {:"X-API-Key" => API_KEY}).and_return bni_http_response
            
          expect(subject.attributes).to match bni_inquiry_response.attributes
        end
  
        context 'when cutoff time' do
          before { allow(Time).to receive(:now).and_return(Time.parse('17:00')) }
  
          it { 
            expect{ subject }.to raise_error(Exceptions::ClosedTimeError) }
        end
      end

      context 'Invalid CardNumber' do
        let(:bni_http_response) {{
          "soapenv:Body": {
            "@xmlns:soapenc": "http://schemas.xmlsoap.org/soap/encoding/",
            "@xmlns:xsd": "http://www.w3.org/2001/XMLSchema",
            "@xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
            "soapenv:Fault": {
              "@xmlns:m": "http://service.bni.co.id/payment",
              "@xmlns:exsl": "http://exslt.org/common",
              "faultcode": "m:Fault",
              "faultstring": "Maaf, pembayaran kartu kredit bank Anda belum dapat dilayani melalui channel ini",
              "detail": {
                "@encodingStyle": "",
                "pa:Fault_element": {
                  "@xmlns:pa": "http://service.bni.co.id/payment",
                  "errorCode": "CC_BNI14",
                  "errorDescription": "Maaf, pembayaran kartu kredit bank Anda belum dapat dilayani melalui channel ini"
                }
              }
            }
          }
        }.to_json}
  
        let (:response_error) {
          ResponseGeneralizer::CreditCardBill.new do |res|
            res.status = FAILED
            res.response_code = "CC_BNI14"
          end
        }
  
        it 'return response error' do
          expect(subject.attributes).to match response_error.attributes
        end
      end
    
      context 'biller inquiry failed' do
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
  
        it 'failed inquiry' do
          expect(subject.attributes).to match response.attributes
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
  
        it 'connection timeout' do
          allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exception.new('Connection timeout'))
          expect(subject.attributes).to match response.attributes
        end
      end
    end

    context 'with non BNI credit card' do
      let(:credit_card_partner) { build_stubbed(:credit_card_bill_partner, :bni)}

      before do
        allow(credit_card_biller).to receive(:partner).and_return(credit_card_partner)
      end

      context 'when using ANZ brand' do
        let(:object) { Form::CreditCardBill.new("4157362568000001", 1234) } #ANZ
        let(:credit_card_biller) { build_stubbed(:credit_card_biller, :anz, id: 1234) }
        let(:expected_response) {
          ResponseGeneralizer::CreditCardBill.new do |res|
            res.card_data = object.customer_number
            res.customer_number = "4157-36XX-XXXX-0001"
            res.biller = object.biller
            res.partner = object.biller.partner
            res.status = 'success'
            res.response_code = 'success'
          end
        }

        it 'should not create connection to BNI and return response' do
          expect(subject.attributes).to match expected_response.attributes
        end
      end

      context 'when using AMEX brand' do
        let(:object) { Form::CreditCardBill.new("344461336626329", 9876) } #AMEX
        let(:credit_card_biller) { build_stubbed(:credit_card_biller, :amex, id: 9876) }
        let(:expected_response) {
          ResponseGeneralizer::CreditCardBill.new do |res|
            res.card_data = "C#{object.customer_number}"
            res.customer_number = "3444-61XX-XXX6-329"
            res.biller = object.biller
            res.partner = object.biller.partner
            res.status = 'success'
            res.response_code = 'success'
          end
        }

        it 'should not create connection to BNI and return response' do
          expect(subject.attributes).to match expected_response.attributes
        end
      end
    end
  end
end
