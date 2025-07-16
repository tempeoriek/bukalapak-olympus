require "rails_helper"
require 'examples/ayoconnect_examples'

RSpec.describe Channel::Ayoconnect::Base, type: :model do
  include_context 'ayoconnect_lets'

  let(:customer_number) { "516070377764" }
  let(:form) { Form::ElectricityPostpaid.new(customer_number) }
  let(:transaction) { build(:postpaid_transaction_with_bill) }

  let(:payload) {
    {
      partnerId: "partner_api_key",
      accountNumber: "516070377764",
      productCode: "LSTPPPOG"
    }
  }

  let(:product_type) { ELECTRICITY_PRODUCT }

  let(:check_status_payload) {
    {
      partnerId: "partner_api_key",
      refNumber: "test-004"
    }
  }

  subject { Channel::Ayoconnect::Base.new }

  context "inquiry" do
    before do
      subject.instance_variable_set(:@object, form)

      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).at_most(5).times.and_return(true)
    end

    context 'when circuit breaker toggle is not active' do
      context 'success request' do
        let(:status) { :success }
        let(:rc) { '300' }
        let(:partner_response) { valid_inquiry_response.to_json }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
          expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
            .to receive(:active?)
            .and_return(false)
        end

        it 'does not raise error' do
          expect { subject.inquiry(payload, product_type) }.not_to raise_error
        end

        it 'returns partner response' do
          expect(subject.inquiry(payload, product_type)).to eq valid_inquiry_response.with_indifferent_access
        end
      end

      context 'timeout' do
        let(:status) { :timeout }
        let(:rc) { 'error' }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
          expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
            .to receive(:active?)
            .at_most(5).times.and_return(false)
        end

        it 'raises timeout error' do
          expect { subject.inquiry(payload, product_type) }.to raise_error(RestClient::Exceptions::OpenTimeout)
        end
      end

      context 'other exceptions' do
        let(:status) { :error }
        let(:rc) { 'error' }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(StandardError)
          expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
            .to receive(:active?)
            .and_return(false)
        end

        it 'raises error' do
          expect { subject.inquiry(payload, product_type) }.to raise_error(StandardError)
        end
      end

      context 'failed response' do
        let(:status) { :failed }
        let(:rc) { '304' }
        let(:partner_response) { failed_inquiry_response.to_json }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
          allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
          
          autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success)
          allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :success).and_return(autoswitch_instance)
          allow(autoswitch_instance).to receive(:run!).and_return true
          
          expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
            .to receive(:active?)
            .and_return(false)
        end

        it 'raise error' do
          expect { subject.inquiry(payload, product_type) }.to raise_error(::Exceptions::UnregisteredNumber)
        end
      end

      context 'failed partner inquiry response' do
        let(:status) { :failed }
        let(:rc) { '313' }
        let(:partner_response) { failed_partner_inquiry_response.to_json }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
          allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
          
          autoswitch_instance = Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :failed)
          allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(action: 'inquiry', status: :failed).and_return(autoswitch_instance)
          allow(autoswitch_instance).to receive(:run!).and_return true

          expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
            .to receive(:active?)
            .and_return(false)
        end

        it 'raise error' do
          expect { subject.inquiry(payload, product_type) }.to raise_error(::Exceptions::TransactionCannotBeDone)
        end
      end
    end

    context 'when circuit breaker is active' do
      let(:sleep_window) { 60 }
      let(:time_window) { 30 }
      let(:volume_threshold) { 10 }
      let(:error_threshold) { 50 }
      let(:circuitbox_configuration) do
        {
          exceptions: [Exceptions::SocketConnectionTimeout, RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT],
          sleep_window: sleep_window,
          time_window: time_window,
          volume_threshold: volume_threshold,
          error_threshold: error_threshold
        }
      end

      context 'when no error' do
        let(:status) { :success }
        let(:rc) { '300' }
        let(:partner_response) { valid_inquiry_response.to_json }

        before do
          allow(Channel::Connection::Http)
            .to receive_message_chain(:post, :body)
            .and_return(partner_response)

          expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
            .to receive(:active?)
            .and_return(true)
        end

        it 'does not raise error' do
          expect { subject.inquiry(payload, product_type) }.not_to raise_error
        end

        it 'returns partner response' do
          expect(subject.inquiry(payload, product_type)).to eq valid_inquiry_response.with_indifferent_access
        end
      end

      context 'when error' do
        let(:status) { :error }
        let(:rc) { 'error' }

        context 'when Circuitbox::OpenCircuitError error occurred' do
          before do
            expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
              .to receive(:active?)
              .and_return(true)

            expect(::CircuitBreaker)
              .to receive(:run)
              .with(:ayoconnect_inquiry, circuitbox_configuration)
              .and_raise(Exceptions::CircuitOpen.new)
          end

          it 'raises CircuitOpen exception' do
            expect { subject.inquiry(payload, product_type) }.to raise_error(Exceptions::CircuitOpen)
          end
        end

        context 'when Circuitbox::ServiceFailureError error occurred' do
          context 'when RestClient::Exceptions::OpenTimeout raised' do
            let(:status) { :timeout }
            let(:rc) { 'error' }

            before do
              allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
              expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
                .to receive(:active?)
                .at_most(5).times.and_return(true)
            end

            it 'raises service failure original error' do
              expect { subject.inquiry(payload, product_type) }.to raise_error(RestClient::Exceptions::OpenTimeout)
            end
          end

          context 'when RestClient::Exceptions::ReadTimeout raised' do
            let(:status) { :timeout }
            let(:rc) { 'error' }

            before do
              allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::ReadTimeout)
              expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
                .to receive(:active?)
                .at_most(5).times.and_return(true)
            end

            it 'raises service failure original error' do
              expect { subject.inquiry(payload, product_type) }.to raise_error(RestClient::Exceptions::ReadTimeout)
            end
          end
        end

        context 'when Exceptions::InternalError raised' do
          before do
            expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
              .to receive(:active?)
              .and_return(true)

            expect(::CircuitBreaker)
              .to receive(:run)
              .with(:ayoconnect_inquiry, circuitbox_configuration)
              .and_raise(Exceptions::InternalError)
          end

          it 'raises internal error' do
            expect { subject.inquiry(payload, product_type) }.to raise_error(Exceptions::InternalError)
          end
        end
      end
    end
  end

  context "create transaction" do
    let(:payload) {
      {
        partnerId: "partner_api_key",
        accountNumber: customer_number,
        productCode: "LSTPPPOG",
        inquiryId: 333333,
        refNumber: "test-002",
        amount: 451500
      }
    }

    before do
      subject.instance_variable_set(:@object, form)

      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).at_most(5).times.and_return(true)
    end

    context 'success request' do
      let(:status) { :pending }
      let(:rc) { '299' }
      let(:partner_response) { valid_create_response.to_json }
      let(:channel_response) {
        valid_create_response.merge({
          "customer_number"=>"516070377764",
          "partner_transaction_id"=>"141793",
          "status"=>::Postpaid::Constant::PENDING
        }).with_indifferent_access
      }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
      end

      it 'does not raise error' do
        expect { subject.create(payload) }.not_to raise_error
      end

      it 'returns partner response' do
        expect(subject.create(payload)).to eq channel_response
      end
    end

    context 'timeout' do
      let(:status) { :timeout }
      let(:rc) { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
          .to receive(:active?)
          .at_most(5).times.and_return(false)
      end

      it 'raises timeout error' do
        expect { subject.create(payload) }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end

    context 'other exceptions' do
      let(:status) { :error }
      let(:rc) { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(StandardError)
        expect(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect)
          .to receive(:active?)
          .and_return(false)
      end

      it 'raises error' do
        expect { subject.inquiry(payload, product_type) }.to raise_error(StandardError)
      end
    end

    context 'failed response' do
      let(:status) { :failed }
      let(:rc) { '100' }
      let(:partner_response) { failed_create_response.to_json }
      let(:channel_response) {
        failed_create_response.merge({
          "customer_number"=>nil,
          "partner_transaction_id"=>nil,
          "status"=>::Postpaid::Constant::FAILED
        }).with_indifferent_access
      }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
      end

      it 'does not raise error' do
        expect { subject.create(payload) }.not_to raise_error
      end

      it 'returns partner response' do
        expect(subject.create(payload)).to eq channel_response
      end
    end

    context 'failed but excluded response' do
      let(:status) { :pending }
      let(:rc) { '102' }
      let(:partner_response) { failed_create_response.merge({'responseCode' => 102}).to_json }
      let(:channel_response) {
        failed_create_response.merge({
          'responseCode'=>102,
          "customer_number"=>nil,
          "partner_transaction_id"=>nil,
          "status"=>::Postpaid::Constant::PENDING
        }).with_indifferent_access
      }

      before do
        stub_const('Channel::Ayoconnect::Helpers::ResponseCode::PAYMENT_FAILED_EXCLUDED_RC', %w[102])
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
      end

      it 'does not raise error' do
        expect { subject.create(payload) }.not_to raise_error
      end

      it 'returns partner response with pending status' do
        expect(subject.create(payload)).to eq channel_response
      end
    end

    context 'when read timeout' do
      let(:status) { :timeout }
      let(:rc) { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::ReadTimeout)
      end

      it 'raises timeout error' do
        expect { subject.create(payload) }.to raise_error(RestClient::Exceptions::ReadTimeout)
      end
    end
  end

  context "check status" do
    before do
      subject.instance_variable_set(:@object, transaction)

      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product, :status => status, :response_code => rc
      )).at_most(5).times.and_return(true)
    end

    context 'success transaction response' do
      let(:status) { :success }
      let(:rc) { '0' }
      let(:partner_response) { check_status_success_response.to_json }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
      end

      it 'does not raise error' do
        expect { subject.check_status(check_status_payload) }.not_to raise_error
      end

      it 'returns partner response with success status' do
        final_status_hash = {
          status: ::Postpaid::Constant::SUCCESS,
          partner_transaction_id: check_status_success_response[:data][:transactionId].to_s,
          customer_number: check_status_success_response[:data][:accountNumber]
        }
        expect(subject.check_status(check_status_payload)).to eq check_status_success_response.merge(final_status_hash).with_indifferent_access
      end
    end

    context 'failed transaction response' do
      let(:status) { :failed }
      let(:rc) { '103' }
      let(:partner_response) { check_status_fail_response.to_json }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
      end

      it 'does not raise error' do
        expect { subject.check_status(check_status_payload) }.not_to raise_error
      end

      it 'returns partner response with failed status' do
        final_status_hash = {
          status: ::Postpaid::Constant::FAILED,
          partner_transaction_id: check_status_fail_response[:data][:transactionId].to_s,
          customer_number: check_status_fail_response[:data][:accountNumber]
        }
        expect(subject.check_status(check_status_payload)).to eq check_status_fail_response.merge(final_status_hash).with_indifferent_access
      end
    end

    context 'pending transaction response' do
      let(:status) { :pending }
      let(:rc) { '299' }
      let(:partner_response) { check_status_pending_response.to_json }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
      end

      it 'does not raise error' do
        expect { subject.check_status(check_status_payload) }.not_to raise_error
      end

      it 'returns partner response with pending' do
        final_status_hash = {
          status: ::Postpaid::Constant::PENDING,
          partner_transaction_id: check_status_pending_response[:data][:transactionId].to_s,
          customer_number: check_status_pending_response[:data][:accountNumber]
        }
        expect(subject.check_status(check_status_payload)).to eq check_status_pending_response.merge(final_status_hash).with_indifferent_access
      end
    end

    context 'failed but excluded response' do
      let(:status) { :pending }
      let(:rc) { '103' }
      let(:partner_response) { check_status_fail_response.to_json }

      before do
        stub_const('Channel::Ayoconnect::Helpers::ResponseCode::PAYMENT_FAILED_EXCLUDED_RC', %w[103])
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
      end

      it 'does not raise error' do
        expect { subject.check_status(check_status_payload) }.not_to raise_error
      end

      it 'returns partner response with pending status' do
        final_status_hash = {
          status: ::Postpaid::Constant::PENDING,
          partner_transaction_id: check_status_fail_response[:data][:transactionId].to_s,
          customer_number: check_status_fail_response[:data][:accountNumber]
        }
        expect(subject.check_status(check_status_payload)).to eq check_status_fail_response.merge(final_status_hash).with_indifferent_access
      end
    end

    context 'timeout' do
      let(:status) { :timeout }
      let(:rc) { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'raises timeout error' do
        expect { subject.check_status(check_status_payload) }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end

    context 'request failed' do
      let(:status) { :error }
      let(:rc) { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exception)
      end

      it 'raises error' do
        expect { subject.check_status(check_status_payload) }.to raise_error(RestClient::Exception)
      end
    end

    context 'transaction not available' do
      let(:status) { :pending }
      let(:rc) { '188' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(unavailable_check_trx_response.to_json)
      end

      it 'raises error' do
        expect { subject.check_status(check_status_payload) }.to raise_error(::Exceptions::PartnerTransactionNotFound)
      end
    end

    context 'other error' do
      let(:status) { :error }
      let(:rc) { 'error' }

      before do
        allow(Channel::Connection::Http).to receive(:post).and_raise(StandardError)
      end

      it 'raises error' do
        expect { subject.check_status(check_status_payload) }.to raise_error(StandardError)
      end
    end
  end

  describe "cache to redis" do
    let(:product_type) { ELECTRICITY_PRODUCT }
    let(:action) { "inquiry" }
    let(:partner) { TEKTAYA }
    let(:reference_id) { '0812345567678' }
    let(:response_code) { MiddlemanResponseMapperUtility::TektayaRC::BILL_ALREADY_PAID }

    subject {Channel::Tektaya::Base.new(form).cache_partner_response(product_type, action, partner, reference_id, response_code) }
    context "when succesfully caching partner response with ELECTRICITY_PRODUCT" do
      before {
        expect(RedisOlympus).to receive(:set).with(kind_of(String), response_code, hash_including(:ex))
      }
      it do
        is_expected.to be_nil
      end
    end
  end
end
