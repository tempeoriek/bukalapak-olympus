require "rails_helper"
include PostpaidTransactionUtility

RSpec.describe Channel::BNI::CreditCardBill, :credit_card_bill, type: :model do
  describe 'create_transaction' do
    subject { Channel::BNI::CreditCardBill.new(object).create_transaction }

    let(:cc_biller) { create(:credit_card_biller, :bni, :partner_bni) }
    let(:object) { create(:cc_transaction, :processed, credit_card_biller_id: cc_biller.id, credit_card_bill_partner_id: cc_biller.partner.id) }

    before do
      allow(CreditCardBiller).to receive(:find).and_return cc_biller
      allow(Keystore).to receive(:get).and_return("dummy_token")
      allow(Keystore).to receive(:expire).and_return(true)
      allow(Channel::Connection::Http).to receive(:post).and_return bni_http_response
    end

    context 'biller BNI succeed' do
      let (:response) {
        ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = SUCCESS
            res.response_code = BNI_SUCCESS
            res.partner_journal_number = "123456789   "
            res.partner_financial_journal_number = "123456"
        end
      }
      let(:bni_http_response) {{
        "trxType": "41",
        "status": "success",
        "data": {
            "error": false,
            "ket": "Credit Card BNI",
            "financialJournal": "123456",
            "journal": "123456789   ",
            "cardNum": "4444333322221111",
            "accountNum": "115258134",
            "amount": "2000000"
        },
        "result": {
            "kode_loket": "BNI25950300",
            "kd_lkt": "50300",
            "nama": "Firda",
            "kode_cabang": "259",
            "kode_mitra": "BNI",
            "alamat": "01/01 Setiabudi Setia Budi Kota Jakarta Selatan DKI Jakarta 12910"
        },
        "CustomerData": {
            "biaya_adm": 0,
            "nominal": "6030",
            "time": "2017‐05‐12T13:25:22+07:00"
        }
      }.to_json}

      it 'success payment' do
        expect(Channel::Connection::Http).to receive(:post).with(anything, anything, hash_including(data: hash_including(amount: object.base_amount)), anything).and_return bni_http_response
        expect(subject.attributes).to match response.attributes
      end
    end

    context 'biller BNI failed' do
      let (:response) {
        ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = FAILED
          res.response_code = "9990"
        end
      }
      let(:bni_http_response) {{
        "trxType": "41",
        "status": "success",
        "data": {
          "error": true,
          "errorNum": "9990",
          "message": "Duplicate Refference Number"
        },
        "result": {
          "kode_loket": "BNI25950300",
          "kd_lkt": "50300",
          "nama": "Firda",
          "kode_cabang": "259",
          "kode_mitra": "BNI",
          "alamat": "01/01 Setiabudi Setia Budi Kota Jakarta Selatan DKI Jakarta 12910"
        },
        "CustomerData": {
          "biaya_adm": 0,
          "nominal": "6030",
          "time": "2018-01-22T18:27:22+07:00"
        }
      }.to_json}

      it 'failed payment' do
        expect(subject.attributes).to match response.attributes
      end
    end

    context 'biller Non BNI succeed' do
      let (:response) {
        ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = SUCCESS
            res.response_code = BNI_SUCCESS
            res.partner_journal_number = "123456789   "
            res.partner_financial_journal_number = "123456"
        end
      }
      let(:bni_http_response) {{
        "trxType": "42",
        "status": "success",
        "data": {
            "error": false,
            "ket": "BRI",
            "financialJournal": "123456",
            "journal": "123456789   ",
            "reffNum": "20170811153652020990"
        },
        "result": {
            "kode_loket": "IPY01400005",
            "kd_lkt": "00005",
            "nama": "Agung",
            "kode_cabang": "014",
            "kode_mitra": "IPY",
            "alamat": "06/28 Ngadirgo Krian Sidoarjo Jawa Timur 50213"
        },
        "CustomerData": {
            "cardNum": "4365020922600613",
            "bankCode": "BRI",
            "biaya_adm": "7500",
            "nominal": "250010",
            "time": "2017‐08‐11T09:17:07+07:00"
        }
      }.to_json}

      it 'success payment' do
        expect(Channel::Connection::Http).to receive(:post).with(anything, anything, hash_including(data: hash_including(amount: object.base_amount)), anything).and_return bni_http_response
        expect(subject.attributes).to match response.attributes
      end
    end

    context 'biller Non BNI failed' do
      let (:response) {
        ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = FAILED
          res.response_code = "9990"
        end
      }
      let(:bni_http_response) {{
        "trxType": "42",
        "status": "success",
        "data": {
          "error": true,
          "errorNum": "9990",
          "message": "Duplicate Refference Number"
        },
        "result": {
          "kode_loket": "IPY01400005",
          "kd_lkt": "00005",
          "nama": "Agung",
          "kode_cabang": "014",
          "kode_mitra": "IPY",
          "alamat": "06/28 Ngadirgo Krian Sidoarjo Jawa Timur 50213"
        },
        "CustomerData": {
          "cardNum": "4365020922600613",
          "bankCode": "BRI",
          "biaya_adm": "7500",
          "nominal": "250000",
          "time": "2018-01-22T19:06:22+07:00"
        }
      }.to_json}

      it 'failed payment' do
        expect(subject.attributes).to match response.attributes
      end
    end

    context 'when get response with timeout messgae' do
      let(:bni_http_response) {{
        "trxType": "41",
        "status": "success",
        "data": {
            "error": true,
            "errorNum": "9999",
            "message": "Timeout - Failed to establish a backside connection"
        },
        "result": {
            "kode_loket": "BNI25950300",
            "kd_lkt": "50300",
            "nama": "Firda",
            "kode_cabang": "259",
            "kode_mitra": "BNI",
            "alamat": "01/01 Setiabudi Setia Budi Kota Jakarta Selatan DKI Jakarta 12910"
        },
        "CustomerData": {
            "biaya_adm": 0,
            "nominal": "6030",
            "time": "2017‐05‐12T13:25:22+07:00"
        }
      }.to_json}

      let(:response_pending) {
        ResponseGeneralizer::CreditCardBill.new do |res|
          res.status = PENDING
          res.response_code = BNI_TIMEOUT
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

    context 'when confirm trx' do
      let(:cc_biller) { create(:credit_card_biller, :bni, :partner_bni) }
      let(:bni_http_response) { {} }
      subject { Channel::BNI::CreditCardBill.new(object).confirm_transaction }

      it { expect { subject }.to raise_error(::Exceptions::ManualCheckError) }
    end
  end
end
