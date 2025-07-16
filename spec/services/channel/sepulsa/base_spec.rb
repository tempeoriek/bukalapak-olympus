require "rails_helper"

RSpec.describe Channel::Sepulsa::Base, type: :model do
  let(:customer_number) { "512345600003" }
  let(:order_id) { "ELP-1" }
  let(:electricity_payload) {
    {
      product_id: 80,
      customer_number: '512345600003',
      order_id: 'ELP-1'
    }
  }
  let(:response_status_not_boolean) {
    {
      status: "fail"
    }
  }
  let(:response_status_false) {
    {
      status: false
    }
  }
  let(:valid_inquiry_response) {
    {
      subscriber_id: "512345600003",
      subscriber_name: "ABDUL GHALIB             ",
      subscriber_segmentation: "R1  ",
      power: "900",
      outstanding_bill: "3",
      stand_meter_summary: "00027135 - 00027588",
      bills: [
        {
            bill_period: "200912",
            due_date: "20091221",
            total_electricity_bill: "00000085875",
            penalty_fee: "000016000",
            previous_meter_reading1: "00027135",
            current_meter_reading1: "00027280"
        },
        {
            bill_period: "201001",
            due_date: "20100122",
            total_electricity_bill: "00000088935",
            penalty_fee: "000000000",
            previous_meter_reading1: "00027280",
            current_meter_reading1: "00027431"
        },
        {
            bill_period: "201002",
            due_date: "20100220",
            total_electricity_bill: "00000091995",
            penalty_fee: "000000000",
            previous_meter_reading1: "00027431",
            current_meter_reading1: "00027588"
        }
      ],
      status: true,
      response_code: "00"
    }
  }
  let(:response_code_fail) {
    {
      response_code: "99"
    }
  }
  let(:valid_create_response) {
    {
      transaction_id: 1,
      status: "pending",
      response_code: "10"
    }
  }
  let(:expected_result_create) {
    {
      partner_transaction_id: "1",
      status: 0
    }
  }
  let(:invalid_transaction_id) { "1234abcd" }
  let(:valid_transaction_id) { "1" }
  let(:valid_get_response) {
    {
      transaction_id: 1,
      status: "success",
      response_code: "00"
    }
  }
  let(:expected_result_get) {
    {
      partner_transaction_id: "1",
      status: 2
    }
  }
  let(:transaction_empty) {
    {
      list: []
    }
  }
  let(:transaction_exist) {
    {
      list: [
        {
          data:
          {
            transaction_id: 1,
            status: "success",
            response_code: "00"
          }
        }
      ]
    }
  }

  subject { Channel::Sepulsa::Base.new }

  context "inquiry" do
    before do
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).and_return(true)
      allow(Channel::Connection::Http).to receive(:post).and_return(response_status)
      allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
    end

    context 'should raise error if response status not boolean' do
      let(:status) { :error }
      let(:rc) { 'error' }
      let(:response_status) { response_status_not_boolean.to_json }

      before do
        autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success)
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success).and_return(autoswitch_instance)
        expect(autoswitch_instance).to receive(:run!).and_return true
      end

      it do
        expect { subject.inquiry(electricity_payload) }.to raise_error(::Exceptions::DefaultError)
      end
    end

    context 'should raise error if response status is false' do
      let(:status) { :error }
      let(:rc) { 'error' }
      let(:response_status) { response_status_false.to_json }

      before do
        autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success)
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success).and_return(autoswitch_instance)
        expect(autoswitch_instance).to receive(:run!).and_return true
      end

      it do
        expect { subject.inquiry(electricity_payload) }.to raise_error(::Exceptions::DefaultError)
      end
    end

    context 'should not raise error if response status is true' do
      let(:status) { :success }
      let(:rc) { '00' }
      let(:response_status) { valid_inquiry_response.to_json }

      it do
        expect { subject.inquiry(electricity_payload) }.not_to raise_error
      end
    end

    context 'should not raise error if timeout' do
      let(:status) { :timeout }
      let(:rc) { 'error' }
      let(:response_status) { valid_inquiry_response.to_json }

      before do
        autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed)
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed).and_return(autoswitch_instance)
        expect(autoswitch_instance).to receive(:run!).and_return true
      end

      it do
        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exceptions::OpenTimeout)
        expect { subject.inquiry(electricity_payload) }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end
  end

  context "create transaction" do
    before do
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).and_return(true)
      allow(Channel::Connection::Http).to receive(:post).and_return(response_status)
    end

    context 'should raise error if response code is failed' do
      let(:status) { :error }
      let(:rc) { '99' }
      let(:response_status) { response_code_fail.to_json }

      it do
        expect { subject.create(electricity_payload) }.to raise_error(::Exceptions::DefaultError)
      end
    end

    context 'should not raise error if response code is pending' do
      let(:status) { :pending }
      let(:rc) { '10' }
      let(:response_status) { valid_create_response.to_json }

      it do
        expect { subject.create(electricity_payload) }.not_to raise_error
      end
    end

    context 'should raise error if timeout' do
      let(:status) { :timeout }
      let(:rc) { 'error' }
      let(:response_status) { valid_create_response.to_json }

      it do
        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exceptions::OpenTimeout)

        expect { subject.create(electricity_payload) }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end
  end

  context "get transaction" do
    before do
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).and_return(true)
      allow(Channel::Connection::Http).to receive(:get).and_return(response_status)
    end

    context 'should raise error if transaction id is invalid' do
      let(:status) { :error }
      let(:rc) { 'error' }
      let(:response_status) { nil }

      it do
        allow(Channel::Connection::Http).to receive(:get).and_raise(RestClient::Exception)
        expect { subject.get_transaction_by_id(invalid_transaction_id, ELECTRICITY_PRODUCT) }.to raise_error(::Exceptions::PartnerTransactionNotFound)
      end
    end

    context 'should not raise error if transaction id is valid' do
      let(:status) { :success }
      let(:rc) { '00' }
      let(:response_status) { valid_get_response.to_json }

      it do
        expect { subject.get_transaction_by_id(valid_transaction_id, ELECTRICITY_PRODUCT) }.not_to raise_error
      end
    end

    context 'should raise error if timeout' do
      let(:status) { :timeout }
      let(:rc) { 'error' }
      let(:response_status) { valid_get_response.to_json }

      it do
        allow(Channel::Connection::Http).to receive(:get).and_raise(RestClient::Exceptions::OpenTimeout)

        expect { subject.get_transaction_by_id(valid_transaction_id, ELECTRICITY_PRODUCT) }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end
  end

  context "get by order id" do
    before do
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).and_return(true)
      allow(Channel::Connection::Http).to receive(:get).and_return(response_status)
    end

    context 'should raise error if there is no transaction' do
      let(:status) { :error }
      let(:rc) { 'error' }
      let(:response_status) { transaction_empty.to_json }

      it do
        expect { subject.get_transaction_by_order_id(order_id, ELECTRICITY_PRODUCT) }.to raise_error(::Exceptions::PartnerTransactionNotFound)
      end
    end

    context 'should return response if there is transaction' do
      let(:status) { :success }
      let(:rc) { '00' }
      let(:response_status) { transaction_exist.to_json }

      it do
        expect { subject.get_transaction_by_order_id(order_id, ELECTRICITY_PRODUCT) }.not_to raise_error
      end
    end

    context 'should raise error if timeout' do
      let(:status) { :timeout }
      let(:rc) { 'error' }
      let(:response_status) { transaction_empty.to_json }

      it do
        allow(Channel::Connection::Http).to receive(:get).and_raise(RestClient::Exceptions::OpenTimeout)

        expect { subject.get_transaction_by_order_id(order_id, ELECTRICITY_PRODUCT) }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end
  end
end
