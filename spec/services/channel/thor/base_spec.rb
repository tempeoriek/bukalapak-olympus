require 'rails_helper'
require 'examples/thor_examples'

RSpec.describe Channel::Thor::Base, type: :model do
  include_context 'thor_lets'

  subject { Channel::Thor::Base.new }

  let(:customer_number) { '19989000000' }
  let(:operator) { build_stubbed(:pdam_operator) }
  let(:product_type) { 'pdam' }
  let(:form) { Form::Pdam.new(customer_number, operator.id) }
  let(:access_token) { 'Bearer token.dummy.abc' }
  let(:transaction) { build_stubbed(:pdam_transaction_with_bill) }

  before do
    allow(PdamOperator).to receive(:find_by_id).with(operator.id).and_return(operator)
  end

  describe 'O2OVPD-600: .inquiry' do
    let(:url) { '/v1/transactions/water-bills/customers' }
    let(:payload) do
      {
        customer_number: form.customer_number,
        product_code: form.operator.code
      }
    end
    let(:restclient_request) { RestClient::Request.new(method: :post, url: Channel::Config::THOR_HOST + url) }

    before do
      described_class::THOR_RESPONSE_INQUIRY_KEY = 'water_bill_customer'.freeze
      described_class::INQUIRY_URL = '/v1/transactions/water-bills/customers'.freeze
      subject.instance_variable_set(:@object, form)
      allow(subject).to receive(:access_token).and_return(access_token)

      allow(::Toggle::CircuitBreaker::Thor)
        .to receive(:active?)
        .and_return(circuit_breaker_active)
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
                                                                                      :action, :partner, :product, :biller_product, status: status, response_code: rc
                                                                                    )).at_most(5).times.and_return(true)
    end

    context 'when circuit breaker is inactive' do
      let(:circuit_breaker_active) { false }

      context 'when success' do
        let(:status) { :success }
        let(:rc) { '0000' }
        let(:partner_response) { success_inquiry_response.to_json }

        before do
          response = RestClient::Response.create(partner_response, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)
        end

        it 'does not raise error' do
          expect { subject.inquiry(payload) }.not_to raise_error
        end

        it 'returns partner response' do
          expect(subject.inquiry(payload)).to eq success_inquiry_response['water_bill_customer']
        end
      end

      context 'when timeout' do
        let(:status) { :timeout }
        let(:rc) { 'error' }

        before { allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout) }

        it 'raises timeout error' do
          expect { subject.inquiry(payload) }.to raise_error(RestClient::Exceptions::OpenTimeout)
        end
      end

      context 'when unauthorized' do
        let(:status) { :error }
        let(:rc) { 'error' }
        let(:partner_response) { unauthorized_response.to_json }

        before do
          allow(subject).to receive(:refresh_jwt_token).and_return(access_token)

          response = RestClient::Response.create(partner_response, Net::HTTPUnauthorized.new(1.0, 401, 'UNAUTHORIZED'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)
        end

        it 'raises unauthorized error' do
          expect { subject.inquiry(payload) }.to raise_error(::Exceptions::Thor::Unauthorized)
        end
      end

      context 'when forbidden' do
        let(:status) { :error }
        let(:rc) { 'error' }
        let(:partner_response) { forbidden_response.to_json }

        before do
          response = RestClient::Response.create(partner_response, Net::HTTPForbidden.new(1.0, 403, 'FORBIDDEN'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)
        end

        it 'raises forbidden error' do
          expect { subject.inquiry(payload) }.to raise_error(::Exceptions::Thor::Forbidden)
        end
      end

      context 'other exceptions' do
        let(:status) { :error }
        let(:rc) { 'error' }

        before { allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(StandardError) }

        it 'raises error' do
          expect { subject.inquiry(payload) }.to raise_error(StandardError)
        end
      end

      context 'failed response' do
        let(:status) { :failed }
        let(:rc) { '0014' }
        let(:partner_response) { failed_inquiry_response.to_json }

        before do
          response = RestClient::Response.create(partner_response, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)

          autoswitch_instance = Action::PdamAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success, operator_id: '1')
          allow(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success, operator_id: anything).and_return(autoswitch_instance)
          allow(autoswitch_instance).to receive(:run!).and_return true
        end

        it 'raise error' do
          expect { subject.inquiry(payload) }.to raise_error(::Exceptions::UnregisteredNumber)
        end
      end
    end

    context 'when circuit breaker is active' do
      let(:circuit_breaker_active) { true }
      let(:circuitbox_configuration) do
        {
          exceptions: [Exceptions::SocketConnectionTimeout, RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT],
          sleep_window: 60,
          time_window: 30,
          volume_threshold: 10,
          error_threshold: 50
        }
      end

      context 'when success' do
        let(:status) { :success }
        let(:rc) { '0000' }
        let(:partner_response) { success_inquiry_response.to_json }

        before do
          response = RestClient::Response.create(partner_response, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
          allow(Channel::Connection::Http).to receive(:post).and_return(response)
        end

        it 'does not raise error' do
          expect { subject.inquiry(payload) }.not_to raise_error
        end

        it 'returns partner response' do
          expect(subject.inquiry(payload)).to eq success_inquiry_response['water_bill_customer']
        end
      end

      context 'when error' do
        let(:status) { :error }
        let(:rc) { 'error' }

        context 'when Circuitbox::OpenCircuitError error occurred' do
          before do
            expect(::CircuitBreaker)
              .to receive(:run)
              .with(:thor_inquiry, circuitbox_configuration)
              .and_raise(Exceptions::CircuitOpen.new)
          end

          it 'raises CircuitOpen exception' do
            expect { subject.inquiry(payload) }.to raise_error(Exceptions::CircuitOpen)
          end
        end

        context 'when Circuitbox::ServiceFailureError error occurred' do
          context 'when RestClient::Exceptions::OpenTimeout raised' do
            let(:status) { :timeout }
            let(:rc) { 'error' }

            before { allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout) }

            it 'raises service failure original error' do
              expect { subject.inquiry(payload) }.to raise_error(RestClient::Exceptions::OpenTimeout)
            end
          end

          context 'when RestClient::Exceptions::ReadTimeout raised' do
            let(:status) { :timeout }
            let(:rc) { 'error' }

            before { allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::ReadTimeout) }

            it 'raises service failure original error' do
              expect { subject.inquiry(payload) }.to raise_error(RestClient::Exceptions::ReadTimeout)
            end
          end
        end

        context 'when Exceptions::InternalError raised' do
          before do
            expect(::CircuitBreaker)
              .to receive(:run)
              .with(:thor_inquiry, circuitbox_configuration)
              .and_raise(Exceptions::InternalError)
          end

          it 'raises internal error' do
            expect { subject.inquiry(payload) }.to raise_error(Exceptions::InternalError)
          end
        end
      end
    end
  end

  describe 'O2OVPD-600: .create' do
    let(:url) { '/v1/transactions/water-bills' }
    let(:payload) do
      {
        customer_number: form.customer_number,
        product_code: form.operator.code,
        order_id: Random.rand(1..9)
      }
    end
    let(:restclient_request) { RestClient::Request.new(method: :post, url: Channel::Config::THOR_HOST + url) }
    let(:restclient_request_advice) { RestClient::Request.new(method: :get, url: Channel::Config::THOR_HOST + url + transaction.id.to_s) }
    let(:advice_response_transaction_not_found) { failed_get_transaction_response.to_json }

    before do
      described_class::THOR_RESPONSE_TRANSACTION_KEY = 'water_bill_transaction'.freeze
      described_class::CREATE_TRANSACTION_URL = '/v1/transactions/water-bills'.freeze
      described_class::CONFIRM_URL = '/v1/transactions/water-bills/order-id/'.freeze
      subject.instance_variable_set(:@object, form)
      allow(subject).to receive(:access_token).and_return(access_token)
      advice_response = RestClient::Response.create(advice_response_transaction_not_found, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request_advice)
      allow(Channel::Connection::Http).to receive(:get).and_return(advice_response)

      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
                                                                                      :action, :partner, :product, :biller_product, status: status, response_code: rc
                                                                                    )).at_most(5).times.and_return(true)
    end

    context 'when success' do
      let(:status) { :success }
      let(:rc) { '0000' }
      let(:partner_response) { success_create_transaction_response.to_json }
      let(:channel_response) do
        success_create_transaction_response[:water_bill_transaction].merge!(
          status: ::Postpaid::Constant::SUCCESS
        ).with_indifferent_access
      end

      before do
        response = RestClient::Response.create(partner_response, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
      end

      it 'does not raise error' do
        expect { subject.create(payload) }.not_to raise_error
      end

      it 'returns partner response' do
        expect(subject.create(payload)).to eq channel_response
      end
    end

    context 'when pending' do
      let(:status) { :pending }
      let(:rc) { '0063' }
      let(:partner_response) { pending_create_transaction_response.to_json }
      let(:channel_response) do
        pending_create_transaction_response[:water_bill_transaction].merge!(
          status: ::Postpaid::Constant::PENDING
        ).with_indifferent_access
      end

      before do
        response = RestClient::Response.create(partner_response, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
      end

      it 'does not raise error' do
        expect { subject.create(payload) }.not_to raise_error
      end

      it 'returns partner response' do
        expect(subject.create(payload)).to eq channel_response
      end
    end

    context 'when timeout' do
      let(:status) { :timeout }
      let(:rc) { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'raises timeout error' do
        expect { subject.create(payload) }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end

    context 'with other RestClient::Exceptions' do
      let(:status) { :error }
      let(:rc) { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exception)
      end

      it 'raises timeout error' do
        expect { subject.create(payload) }.to raise_error(RestClient::Exception)
      end
    end

    context 'with other execptions' do
      let(:status) { :error }
      let(:rc) { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(StandardError)
      end

      it 'raise error' do
        expect { subject.create(payload) }.to raise_error(StandardError)
      end
    end

    context 'when failed response' do
      let(:status) { :failed }
      let(:rc) { '0036' }
      let(:partner_response) { failed_create_transaction_response.to_json }
      let(:channel_response) do
        failed_create_transaction_response[:water_bill_transaction].merge!(
          status: ::Postpaid::Constant::FAILED
        ).with_indifferent_access
      end

      before do
        response = RestClient::Response.create(partner_response, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
      end

      it 'raise error' do
        expect { subject.create(payload) }.not_to raise_error
      end

      it 'returns partner response' do
        expect(subject.create(payload)).to eq channel_response
      end
    end

    context 'when unauthorized' do
      let(:status) { :error }
      let(:rc) { 'error' }
      let(:partner_response) { unauthorized_response.to_json }

      before do
        allow(subject).to receive(:refresh_jwt_token).and_return(access_token)

        response = RestClient::Response.create(partner_response, Net::HTTPUnauthorized.new(1.0, 401, 'UNAUTHORIZED'), restclient_request)
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
      end

      it 'raises unauthorized error' do
        expect { subject.create(payload) }.to raise_error(::Exceptions::Thor::Unauthorized)
      end
    end

    context 'when forbidden' do
      let(:status) { :error }
      let(:rc) { 'error' }
      let(:partner_response) { forbidden_response.to_json }

      before do
        response = RestClient::Response.create(partner_response, Net::HTTPForbidden.new(1.0, 403, 'FORBIDDEN'), restclient_request)
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
      end

      it 'raises forbidden error' do
        expect { subject.create(payload) }.to raise_error(::Exceptions::Thor::Forbidden)
      end
    end
  end

  describe 'O2OVPD-600: .get_transaction_by_id' do
    let(:url) { '/v1/transactions/water-bills/order-id/' }
    let(:restclient_request) { RestClient::Request.new(method: :get, url: Channel::Config::THOR_HOST + url + transaction.id.to_s) }

    before do
      described_class::THOR_RESPONSE_TRANSACTION_KEY = 'water_bill_transaction'.freeze
      described_class::CONFIRM_URL = '/v1/transactions/water-bills/order-id/'.freeze
      subject.instance_variable_set(:@object, transaction)
      allow(subject).to receive(:access_token).and_return(access_token)

      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
                                                                                      :action, :partner, :product, :biller_product, status: status, response_code: rc
                                                                                    )).at_most(5).times.and_return(true)
    end

    context 'when success' do
      let(:status) { :success }
      let(:rc) { '0000' }
      let(:partner_response) { success_get_transaction_response.to_json }
      let(:channel_response) do
        success_get_transaction_response[:water_bill_transaction].merge!(
          status: ::Postpaid::Constant::SUCCESS
        ).with_indifferent_access
      end

      before do
        response = RestClient::Response.create(partner_response, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)
      end

      it 'does not raise error' do
        expect { subject.get_transaction_by_id(transaction.id) }.not_to raise_error
      end

      it 'returns partner response' do
        expect(subject.get_transaction_by_id(transaction.id)).to eq channel_response
      end
    end

    context 'when pending' do
      let(:status) { :pending }
      let(:rc) { '0063' }
      let(:partner_response) { pending_get_transaction_response.to_json }
      let(:channel_response) do
        pending_get_transaction_response[:water_bill_transaction].merge!(
          status: ::Postpaid::Constant::PENDING
        ).with_indifferent_access
      end

      before do
        response = RestClient::Response.create(partner_response, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)
      end

      it 'does not raise error' do
        expect { subject.get_transaction_by_id(transaction.id) }.not_to raise_error
      end

      it 'returns partner response' do
        expect(subject.get_transaction_by_id(transaction.id)).to eq channel_response
      end
    end

    context 'when failed' do
      let(:status) { :error }
      let(:rc) { '0092' }
      let(:partner_response) { failed_get_transaction_response.to_json }
      let(:channel_response) do
        failed_get_transaction_response[:water_bill_transaction].merge!(
          status: ::Postpaid::Constant::FAILED
        ).with_indifferent_access
      end

      before do
        response = RestClient::Response.create(partner_response, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)
      end

      it 'raises error Partner Transaction Not Found' do
        expect { subject.get_transaction_by_id(transaction.id) }.to raise_error(::Exceptions::PartnerTransactionNotFound)
      end
    end

    context 'when timeout' do
      let(:status) { :timeout }
      let(:rc) { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:get, :body).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'raises timeout error' do
        expect { subject.get_transaction_by_id(transaction.id) }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end

    context 'with other errors' do
      let(:status) { :error }
      let(:rc) { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:get, :body).and_raise(StandardError)
      end

      it 'raise error' do
        expect { subject.get_transaction_by_id(transaction.id) }.to raise_error(StandardError)
      end
    end

    context 'when unauthorized' do
      let(:status) { :error }
      let(:rc) { 'error' }
      let(:partner_response) { unauthorized_response.to_json }

      before do
        allow(subject).to receive(:refresh_jwt_token).and_return(access_token)

        response = RestClient::Response.create(partner_response, Net::HTTPUnauthorized.new(1.0, 401, 'UNAUTHORIZED'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)
      end

      it 'raises unauthorized error' do
        expect { subject.get_transaction_by_id(transaction.id) }.to raise_error(::Exceptions::Thor::Unauthorized)
      end
    end

    context 'when forbidden' do
      let(:status) { :error }
      let(:rc) { 'error' }
      let(:partner_response) { forbidden_response.to_json }

      before do
        response = RestClient::Response.create(partner_response, Net::HTTPForbidden.new(1.0, 403, 'FORBIDDEN'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)
      end

      it 'raises forbidden error' do
        expect { subject.get_transaction_by_id(transaction.id) }.to raise_error(::Exceptions::Thor::Forbidden)
      end
    end
  end

  describe 'O2OVPD-600 .cache_partner_response' do
    let(:product_type)  { PDAM_PRODUCT }
    let(:action)        { :inquiry }
    let(:partner)       { THOR }
    let(:reference_id)  { '12345679' }
    let(:response_code) { MiddlemanResponseMapperUtility::ThorRC::BILLS_ALREADY_PAID }

    subject { Channel::Thor::Base.new.cache_partner_response(product_type, action, partner, reference_id, response_code) }

    before do
      described_class::THOR_RESPONSE_TRANSACTION_KEY = 'water_bill_transaction'.freeze
      described_class::INQUIRY_URL = '/v1/transactions/water-bills/customers'.freeze
      RedisOlympus.flushall # remote all keys in Redis
    end

    context 'when redis is empty' do
      it 'should set redis' do
        is_expected.not_to be_nil

        key = RedisOlympus.keys.first
        value = RedisOlympus.get(key)
        expect(value).to eq(response_code)
      end
    end

    context 'when redis is not empty' do
      before do
        key = "cache_partner_response::#{product_type}::#{partner}::#{action}::#{reference_id}"
        RedisOlympus.set(key, '0100', ex: 10_000) # set as unknown error
      end

      it 'should overwrite the value' do
        is_expected.not_to be_nil

        key = RedisOlympus.keys.first
        value = RedisOlympus.get(key)
        expect(value).to eq(response_code)
      end
    end
  end
end
