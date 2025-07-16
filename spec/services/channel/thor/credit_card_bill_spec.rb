require 'rails_helper'
require 'examples/thor_examples'

RSpec.describe Channel::Thor::CreditCardBill, type: :model do
  include_context 'thor_lets'

  let(:biller)                       { create(:credit_card_biller, :cimbniaga_thor) }
  let(:partner)                      { create(:credit_card_bill_partner, :cimbniaga_thor, credit_card_biller: biller, biller_code: 'test') }
  let(:customer_number)              { '199890000000' }
  let(:access_token)                 { 'token.dummy.abc' }

  before do
    Rails.cache.write(described_class::ACCESS_TOKEN_CACHE_KEY, access_token, expires_in: 10_000)
    # RedisOlympus.flushall # remove all keys in Redis
  end

  describe 'O2OVPE-1457: #create_transaction' do
    let(:transaction)        { create(:cc_transaction, :paid, credit_card_biller: biller) }
    let(:restclient_request) { RestClient::Request.new(method: :post, url: Channel::Config::THOR_HOST + described_class::CREATE_TRANSACTION_URL) }
    let(:restclient_request_advice) { RestClient::Request.new(method: :get, url: Channel::Config::THOR_HOST + described_class::CONFIRM_URL + transaction.id.to_s) }
    let(:advice_response_transaction_not_found) { cc_bill_failed_get_transaction_response.to_json }

    subject { described_class.new(transaction).create_transaction }

    before do
      allow(biller).to receive(:partner).and_return(partner)
      advice_response = RestClient::Response.create(advice_response_transaction_not_found, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request_advice)
      allow(Channel::Connection::Http).to receive(:get).and_return(advice_response)

      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
                                                                                      :action, :partner, :product, :biller_product, status: status, response_code: rc
                                                                                    )).at_most(5).times.and_return(true)
    end

    context 'when success' do
      let(:status)           { :success }
      let(:rc)               { '0000' }
      let(:partner_response) { cc_bill_success_payment_response }

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
      let(:rc)               { '0068' }
      let(:partner_response) { cc_bill_pending_payment_transaction_response }

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
      let(:partner_response) { cc_bill_failed_payment_transaction_response }

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

  describe 'O2OVPE-1458: #confirm_transaction' do
    let(:transaction)        { build_stubbed(:cc_transaction, :paid) }
    let(:restclient_request) { RestClient::Request.new(method: :get, url: Channel::Config::THOR_HOST + described_class::CONFIRM_URL + transaction.id.to_s) }

    subject { described_class.new(transaction).confirm_transaction }

    context 'when success' do
      let(:status)           { :success }
      let(:rc)               { '0000' }
      let(:partner_response) { cc_bill_success_payment_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)

        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, status: status, response_code: rc
        )).at_most(5).times.and_return(true)
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
      let(:rc)               { '0068' }
      let(:partner_response) { cc_bill_pending_payment_transaction_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)

        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, status: status, response_code: rc
        )).at_most(5).times.and_return(true)
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
      let(:partner_response) { cc_bill_failed_get_transaction_response }

      before do
        response = RestClient::Response.create(partner_response.to_json, Net::HTTPResponse.new(1.0, 200, 'OK'), restclient_request)
        allow(Channel::Connection::Http).to receive(:get).and_return(response)

        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, status: status, response_code: rc
        )).at_most(5).times.and_return(true)
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

      it 'should raise timeout error' do
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)

        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, status: status, response_code: rc
        )).at_most(5).times.and_return(true)
      end
    end

    context 'with other restclient exceptions' do
      let(:status) { :error }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:get).and_raise(RestClient::Exception)
      end

      it 'should raise error' do
        expect { subject }.to raise_error(RestClient::Exception)

        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, status: status, response_code: rc
        )).at_most(5).times.and_return(true)
      end
    end

    context 'with other errors' do
      let(:status) { :error }
      let(:rc)     { 'error' }

      before do
        allow(Channel::Connection::Http).to receive_message_chain(:get).and_raise(StandardError)
      end

      it 'should raise error' do
        expect { subject }.to raise_error(StandardError)

        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product, status: status, response_code: rc
        )).at_most(5).times.and_return(true)
      end
    end
  end
end
