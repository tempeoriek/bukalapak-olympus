require "rails_helper"

RSpec.describe Channel::Sepulsa::PhoneCredit, type: :model do
  let(:customer_number) { '081234000001' }
  let(:invalid_customer_number) { '0823e1312332' }
  let(:provider) { build_stubbed :phone_credit_provider }
  let(:provider_prefix) { build_stubbed :provider_prefix }
  let(:valid_form) { Form::PhoneCredit.new(customer_number, 123, NORMAL_BUYER_TYPE) }
  let(:invalid_form) { Form::PhoneCredit.new(invalid_customer_number) }
  let(:inquiry_response) {
    {
      customer_no: customer_number,
      customer_name: 'INDAH PRAWITA HAPSARI',
      reference_no: '2203267',
      bill_count: 1,
      bill_periode: '201801',
      bill_amount: 25000,
      admin_fee: 1000,
      total_amount: 26000,
      status: true,
      response_code: '00',
      message: 'success',
      rc: '00',
      trx_id: '',
    }.with_indifferent_access
  }
  let(:payment_response) {
    {
      "transaction_id"  => "143411",
      "type"            => "mobile_postpaid",
      "created"         => "1599726889",
      "changed"         => "1599726889",
      "customer_number" => customer_number,
      "product_id" => {
        "product_id" => "113",
        "type"       => "mobile_postpaid",
        "label"      => "Telkomsel Halo",
        "operator"   => "telkomsel",
        "nominal"    => "500000",
        "price"      => 1230,
        "enabled"    => "1"
      },
      "order_id"        => "PCP-1379760",
      "price"           => "210524",
      "status"          => "pending",
      "response_code"   => "10",
      "serial_number"   => nil,
      "amount"          => "209294",
      "token"           => nil,
      "data"            => nil
    }.with_indifferent_access
  }
  let(:get_transaction_by_order_id_response) {
    {
      "self": "https://horven.sumpahpalapa.com/api/transaction.json?order_id=PCP-5503302302",
      "first": "https://horven.sumpahpalapa.com/api/transaction.json?order_id=PCP-5503302302\\u0026page=1",
      "last": "https://horven.sumpahpalapa.com/api/transaction.json?order_id=PCP-5503302302\\u0026page=1",
      "list": [
        {
          "transaction_id": "146896454",
          "type": "mobile_postpaid",
          "created": "1599718664",
          "changed": "1599718666",
          "customer_number": customer_number,
          "product_id": {
            "product_id": "483",
            "type": "mobile_postpaid",
            "label": "Telkomsel Halo",
            "operator": "Telkomsel",
            "nominal": "0",
            "price": 2000,
            "enabled": "1"
          },
          "order_id": "PCP-5503302302",
          "price": "57000",
          "status": "success",
          "response_code": "00",
          "serial_number": "00994821551",
          "amount": "55000",
          "token": nil,
          "data": {
            "reference_no": "00994821551",
            "response_code": "00",
            "customer_no": customer_number,
            "customer_name": "DEWXXXXXXNAH",
            "bill_count": "1",
            "bill_periode": "202009",
            "bill_amount": "55000",
            "admin_fee": "2000",
            "total_amount": "57000"
          }
        }
      ]
    }.with_indifferent_access
  }
  let(:get_transaction_by_id_response) {
    {
      "transaction_id": "146896454",
      "type": "mobile_postpaid",
      "created": "1599718664",
      "changed": "1599718666",
      "customer_number": customer_number,
      "product_id": {
        "product_id": "483",
        "type": "mobile_postpaid",
        "label": "Telkomsel Halo",
        "operator": "Telkomsel",
        "nominal": "0",
        "price": 2000,
        "enabled": "1"
      },
      "order_id": "PCP-5503302302",
      "price": "57000",
      "status": "success",
      "response_code": "00",
      "serial_number": "00994821551",
      "amount": "55000",
      "token": nil,
      "data": {
        "reference_no": "00994821551",
        "response_code": "00",
        "customer_no": customer_number,
        "customer_name": "DEWXXXXXXNAH",
        "bill_count": "1",
        "bill_periode": "202009",
        "bill_amount": "55000",
        "admin_fee": "2000",
        "total_amount": "57000"
      }
    }.with_indifferent_access
  }

  let(:valid_form_channel) { Channel::Sepulsa::PhoneCredit.new(valid_form) }
  let(:invalid_form_channel) { Channel::Sepulsa::PhoneCredit.new(invalid_form) }

  before do
    allow(ProviderPrefix).to receive(:find_by).with(anything).and_return(nil)
    allow(ProviderPrefix).to receive(:find_by).with(prefix: customer_number[0..3]).and_return(provider_prefix)
    allow(PhoneCreditProvider).to receive(:find).and_return(provider)
    allow(Toggles::PhoneCreditPostpaidMitraAuth).to receive(:active?).and_return false
  end

  describe '#get_auth' do
    subject { described_class.new(valid_form) }

    # before(:each) do
    #   allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)
    # end

    it 'return normal auth' do
      expect(subject.get_auth).to eq(described_class::AUTH)
    end

    context 'when buyer is mitra and toggle is off' do
      let(:valid_form) { Form::PhoneCredit.new(customer_number, 123, AGENT_BUYER_TYPE) }

    it 'return mitra auth' do
        expect(subject.get_auth).to eq(described_class::AUTH)
      end
    end

    context 'when buyer is mitra and toggle is on' do
      let(:valid_form) { Form::PhoneCredit.new(customer_number, 123, AGENT_BUYER_TYPE) }

      before do
        allow(Toggles::PhoneCreditPostpaidMitraAuth).to receive(:active?).and_return true
      end

      it 'return mitra auth' do
        expect(subject.get_auth).to eq(described_class::MITRA_AUTH)
      end
    end
  end

  describe "#inquiry_to_partner" do
    context "invalid phone number" do
      subject { invalid_form_channel }

      context "contains unexpected character" do
        it { expect{ subject.inquiry_to_partner }.to raise_error(Exceptions::InvalidPhoneNumber) }
      end

      context "less than 10 character" do
        let(:invalid_customer_number) { '081234567' }

        it { expect{ subject.inquiry_to_partner }.to raise_error(Exceptions::InvalidPhoneNumber) }
      end

      context "more than 16 character" do
        let(:invalid_customer_number) { '08123456789101112' }

        it { expect{ subject.inquiry_to_partner }.to raise_error(Exceptions::InvalidPhoneNumber) }
      end
    end

    context "valid phone number" do
      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).and_return(true)
      end

      let(:status) { :success }
      let(:rc) { '00' }

      it "should not raise error" do
        allow(Channel::Connection::Http).to receive(:post).and_return(inquiry_response.to_json)

        expect { valid_form_channel.inquiry_to_partner }.not_to raise_error
      end
    end

    context "valid phone number" do
      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, :status => status, :response_code => rc
        )).and_return(true)
      end

      context "with '-' character" do
        let(:status) { :success }
        let(:rc) { '00' }
        let(:customer_number) { '0812-3400-0001' }

        it "should not raise error" do
          allow(Channel::Connection::Http).to receive(:post).and_return(inquiry_response.to_json)

          expect { valid_form_channel.inquiry_to_partner }.not_to raise_error
        end
      end
    end
  end

  describe '#create_transaction' do
    let(:trx) { build(:phone_credit_postpaid_transaction) }
    let(:status) { :pending }
    let(:rc) { '10' }

    subject { described_class.new(trx).create_transaction }
    it 'matches the result' do
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).and_return(true)
      allow(Channel::Connection::Http).to receive(:post).with(described_class::TRANSACTION_URL, any_args).and_return payment_response.to_json
      result = subject
      expect(result.partner_transaction_id).to eq payment_response[:transaction_id]
      expect(result.status).to eq PARTNER_STATUS[SEPULSA][payment_response[:status]]
    end
  end

  describe '#confirm_transaction' do
    before do
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).and_return(true)
    end

    subject { described_class.new(trx).confirm_transaction }

    context 'without partner_transaction_id (request by order_id)' do
      let(:trx) { build(:phone_credit_postpaid_transaction)}
      let(:status) { :success }
      let(:rc) { '00' }

      it 'matches the result' do
        allow(Channel::Connection::Http).to receive(:get).with(described_class::TRANSACTION_URL, any_args).and_return get_transaction_by_order_id_response.to_json
        result = subject
        list_item = get_transaction_by_order_id_response[:list][0]
        expect(result.partner_transaction_id).to eq list_item[:transaction_id]
        expect(result.status).to eq PARTNER_STATUS[SEPULSA][list_item[:status]]
      end
    end

    context 'with partner_transaction_id (request by transaction_id)' do
      let(:trx) { build(:phone_credit_postpaid_transaction, :partner_transaction_id => 123) }
      let(:status) { :success }
      let(:rc) { '00' }

      it 'matches the result' do
        allow(Channel::Connection::Http).to receive(:get).and_return get_transaction_by_id_response.to_json
        result = subject
        expect(result.partner_transaction_id).to eq get_transaction_by_id_response[:transaction_id]
        expect(result.status).to eq PARTNER_STATUS[SEPULSA][get_transaction_by_id_response[:status]]
      end
    end
  end
end
