require 'rails_helper'
require 'examples/thor_examples'

RSpec.describe Channel::Thor::ElectricityPostpaid, type: :model do
  include_context 'thor_lets'

  let(:electricity_postpaid_partner) { build_stubbed(:electricity_postpaid_partner, :vsi_thor) }
  let(:customer_number)              { '199890000000' }
  let(:access_token)                 { 'token.dummy.abc' }

  before do
    Rails.cache.write(described_class::ACCESS_TOKEN_CACHE_KEY, access_token, expires_in: 10_000)
    RedisOlympus.flushall # remove all keys in Redis
  end

  describe 'O2OVPD-1001: #inquiry_to_partner' do
    let(:restclient_request) { RestClient::Request.new(method: :post, url: Channel::Config::THOR_HOST + described_class::INQUIRY_URL) }
    let(:form)               { Form::ElectricityPostpaid.new(customer_number) }

    subject { described_class.new(form).inquiry_to_partner }

    before do
      allow(ElectricityPostpaidPartner).to receive(:find_by).and_return(electricity_postpaid_partner)
      expect(::Toggle::CircuitBreaker::Thor)
        .to receive(:active?)
        .and_return(false)
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
                                                                                      :action, :partner, :product, :biller_product, status: status, response_code: rc
                                                                                    )).at_most(5).times.and_return(true)

      allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
    end

    context 'when success' do
      let(:status)           { :success }
      let(:rc)               { '0000' }
      let(:partner_response) { electricity_postpaid_success_inquiry_response }

      context 'when bills present' do
        before do
          response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)
        end

        it 'should not raise error' do
          expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
          expect { subject }.not_to raise_error
          expect(subject.bills.first[:amount]).to eq 285_305
          expect(subject.bills.first[:penalty_fee]).to eq 16_000
        end
      end

      context 'when bills nil' do
        before do
          partner_response[:postpaid_electricity_customer][:bills] = nil
          response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)
        end

        it 'should not raise error' do
          expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
          expect { subject }.not_to raise_error
        end
      end

      context 'when bills is invalid' do
        let(:invalid_bill_response) { electricity_postpaid_success_inquiry_invalid_bill_response }

        before do
          response = RestClient::Response.create(invalid_bill_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)
        end

        it 'should not raise error' do
          expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
          expect { subject }.not_to raise_error
          expect(subject.bills.first[:amount]).to eq 0
          expect(subject.bills.first[:penalty_fee]).to eq 0
        end
      end
    end

    context 'when failed' do
      context 'with response unknown number' do
        let(:status)           { :failed }
        let(:rc)               { '0014' }
        let(:partner_response) { electricity_postpaid_failed_inquiry_response }

        before do
          response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)

          autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success)
          allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success).and_return(autoswitch_instance)
          allow(autoswitch_instance).to receive(:run!).and_return true
        end

        it 'should raise error' do
          expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
          expect { subject }.to raise_error(::Exceptions::UnregisteredNumber)
        end
      end

      context 'with response bill already paid' do
        let(:status)           { :failed }
        let(:rc)               { '0088' }
        let(:partner_response) { electricity_postpaid_failed_inquiry_response }

        before do
          partner_response[:postpaid_electricity_customer][:response_code] = '0088'
          partner_response[:postpaid_electricity_customer][:message] = 'bills are already paid'
          response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)

          autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success)
          allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success).and_return(autoswitch_instance)
          allow(autoswitch_instance).to receive(:run!).and_return true
        end

        it 'should raise error' do
          expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
          expect { subject }.to raise_error(::Exceptions::BillAlreadyPaid)
        end
      end

      context 'with error timeout with rc' do
        let(:status)           { :failed }
        let(:rc)               { '0068' }
        let(:partner_response) { electricity_postpaid_failed_inquiry_response }

        before do
          partner_response[:postpaid_electricity_customer][:response_code] = '0068'
          partner_response[:postpaid_electricity_customer][:message] = 'timeout'
          response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)

          autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed)
          allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed).and_return(autoswitch_instance)
          expect(autoswitch_instance).to receive(:run!).and_return true
        end

        it 'should raise error' do
          expect(RedisOlympus).to receive(:set).with(kind_of(String), rc, hash_including(:ex))
          expect { subject }.to raise_error(::Exceptions::Thor::DefaultError)
        end
      end

      context 'with error timeout' do
        let(:status)           { :timeout }
        let(:rc)               { 'error' }

        before do
          allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exceptions::OpenTimeout)

          autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed)
          allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed).and_return(autoswitch_instance)
          expect(autoswitch_instance).to receive(:run!).at_most(5).times.and_return true
        end

        it 'should raise error' do
          expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
        end
      end
    end
  end

  describe 'O2OVPD-1002: #create_transaction' do
    let(:transaction)        { build_stubbed(:postpaid_transaction_with_bill, :paid, :vsi_thor) }
    let(:restclient_request) { RestClient::Request.new(method: :post, url: Channel::Config::THOR_HOST + described_class::CREATE_TRANSACTION_URL) }
    let(:restclient_request_advice) { RestClient::Request.new(method: :get, url: Channel::Config::THOR_HOST + described_class::CONFIRM_URL + transaction.id.to_s) }
    let(:advice_response_transaction_not_found) { electricity_postpaid_failed_get_transaction_response.to_json }

    subject { described_class.new(transaction).create_transaction }

    before do
      allow(ElectricityPostpaidPartner).to receive(:find_by).and_return(electricity_postpaid_partner)
      advice_response = RestClient::Response.create(advice_response_transaction_not_found, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request_advice)
      allow(Channel::Connection::Http).to receive(:get).and_return(advice_response)

      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
                                                                                      :action, :partner, :product, :biller_product, status: status, response_code: rc
                                                                                    )).at_most(5).times.and_return(true)
    end

    context 'when success' do
      let(:status)           { :success }
      let(:rc)               { '0000' }
      let(:partner_response) { electricity_postpaid_success_payment_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
      end

      it 'returns success' do
        expect { subject }.not_to raise_error
      end

      it 'return expected results' do
        result = subject
        expect(result.status).to eq SUCCESS
      end
    end

    context 'when pending' do
      let(:status)           { :pending }
      let(:rc)               { '0063' }
      let(:partner_response) { electricity_postpaid_pending_payment_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.status).to eq PENDING
      end
    end

    context 'when failed' do
      let(:status)           { :failed }
      let(:rc)               { '0036' }
      let(:partner_response) { electricity_postpaid_failed_payment_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.status).to eq FAILED
      end
    end

    context 'with restclient timeout' do
      let(:status) { :timeout }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'raises timeout error' do
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end

    context 'with other restclient exceptions' do
      let(:status) { :error }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exception)
      end

      it 'raises error' do
        expect { subject }.to raise_error(RestClient::Exception)
      end
    end

    context 'with other errors' do
      let(:status) { :error }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(StandardError)
      end

      it 'raises error' do
        expect { subject }.to raise_error(StandardError)
      end
    end
  end

  describe 'O2OVPD-1003: #confirm_confirm_transaction' do
    let(:transaction)        { build_stubbed(:postpaid_transaction_with_bill, :paid, :vsi_thor) }
    let(:restclient_request) { RestClient::Request.new(method: :get, url: Channel::Config::THOR_HOST + described_class::CONFIRM_URL + transaction.id.to_s) }

    subject { described_class.new(transaction).confirm_transaction }

    before do
      allow(ElectricityPostpaidPartner).to receive(:find_by).and_return(electricity_postpaid_partner)
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
                                                                                      :action, :partner, :product, :biller_product, status: status, response_code: rc
                                                                                    )).at_most(5).times.and_return(true)
    end

    context 'when success' do
      let(:status)           { :success }
      let(:rc)               { '0000' }
      let(:partner_response) { electricity_postpaid_success_get_transaction_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'return expected results' do
        result = subject
        expect(result.status).to eq SUCCESS
      end
    end

    context 'when pending' do
      let(:status)           { :pending }
      let(:rc)               { '0063' }
      let(:partner_response) { electricity_postpaid_pending_get_transaction_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)
      end

      it 'does not raise error' do
        expect { subject }.not_to raise_error
      end

      it 'returns expected results' do
        result = subject
        expect(result.status).to eq PENDING
      end
    end

    context 'when order not found' do
      let(:status)           { :error }
      let(:rc)               { '0092' }
      let(:partner_response) { electricity_postpaid_failed_get_transaction_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)
      end

      it 'should raise error' do
        expect { subject }.to raise_error(::Exceptions::PartnerTransactionNotFound)
      end
    end

    context 'with restclient timeout' do
      let(:status) { :timeout }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:get).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'raises timeout error' do
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end

    context 'with other restclient exceptions' do
      let(:status) { :error }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:get).and_raise(RestClient::Exception)
      end

      it 'raises error' do
        expect { subject }.to raise_error(RestClient::Exception)
      end
    end

    context 'with other errors' do
      let(:status) { :error }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:get).and_raise(StandardError)
      end

      it 'raises error' do
        expect { subject }.to raise_error(StandardError)
      end
    end
  end
end
