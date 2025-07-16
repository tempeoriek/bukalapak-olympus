# frozen_string_literal: true

require 'rails_helper'
require 'examples/tektaya_examples'

RSpec.describe Channel::Tektaya::Helpers::Login, type: :model do
  include_context 'tektaya_lets'

  let(:url) { 'https://somewhat.com/n/v7/login' }

  let(:payload) {
    {
      mti: '58',
      userid: 'ABCDE',
      password: 'VWXYZ',
      bit62: "12345"
    }
  }

  describe '#request"'do
    context 'when buyer type is NORMAL' do
      subject { described_class.new(described_class::NORMAL_BUYER_TYPE).request }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :status => status, :response_code => rc
        )).at_least(1).times.and_return(true)
      end

      context 'when request is success' do
        let(:status) { :success }
        let(:rc) { '00' }
        let(:partner_response) { valid_login_response.to_json }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
        end

        it 'does not raise error' do
          expect(RedisOlympus).to receive(:set).with(described_class::BL_SESSION_KEY, anything).exactly(1).times
          expect { subject }.not_to raise_error
        end
      end

      context 'when timeout' do
        let(:status) { :error }
        let(:rc) { 'error' }
  
        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
        end
  
        it 'raises timeout error' do
          expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
        end
      end
  
      context 'when other exceptions happened' do
        let(:status) { :error }
        let(:rc) { 'error' }
  
        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(StandardError)
        end
  
        it 'raises error' do
          expect { subject }.to raise_error(StandardError)
        end
      end
  
      context 'when response is failed' do
        let(:status) { :error }
        let(:rc) { '97' }
        let(:partner_response) { invalid_login_response.to_json }
  
        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
        end
  
        it 'raise error' do
          expect { subject }.to raise_error(::Exceptions::PartnerIssue, 'Fail to retrieve session key for Tektaya')
        end
      end
    end

    context 'when buyer type is MITRA' do
      subject { described_class.new(described_class::MITRA_BUYER_TYPE).request }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :status => status, :response_code => rc
        )).at_least(1).times.and_return(true)
      end

      context 'when request is success' do
        let(:status) { :success }
        let(:rc) { '00' }
        let(:partner_response) { valid_login_response.to_json }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
        end

        it 'does not raise error' do
          expect(RedisOlympus).to receive(:set).with(described_class::BMI_SESSION_KEY, anything).exactly(1).times
          expect { subject }.not_to raise_error
        end
      end

      context 'when timeout' do
        let(:status) { :error }
        let(:rc) { 'error' }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
        end

        it 'raises timeout error' do
          expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
        end
      end

      context 'when other exceptions happened' do
        let(:status) { :error }
        let(:rc) { 'error' }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(StandardError)
        end

        it 'raises error' do
          expect { subject }.to raise_error(StandardError)
        end
      end

      context 'when response is failed' do
        let(:status) { :error }
        let(:rc) { '97' }
        let(:partner_response) { invalid_login_response.to_json }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
        end

        it 'raise error' do
          expect { subject }.to raise_error(::Exceptions::PartnerIssue, 'Fail to retrieve session key for Tektaya')
        end
      end
    end

    context 'when buyer type is BUKACONNECT' do
      subject { described_class.new(described_class::BUKACONNECT_BUYER_TYPE).request }

      before do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :status => status, :response_code => rc
        )).at_least(1).times.and_return(true)
      end

      context 'when request is success' do
        let(:status) { :success }
        let(:rc) { '00' }
        let(:partner_response) { valid_login_response.to_json }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
        end

        it 'does not raise error' do
          expect(RedisOlympus).to receive(:set).with(described_class::BMI_BUKACONNECT_SESSION_KEY, anything).exactly(1).times
          expect { subject }.not_to raise_error
        end
      end

      context 'when timeout' do
        let(:status) { :error }
        let(:rc) { 'error' }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(RestClient::Exceptions::OpenTimeout)
        end

        it 'raises timeout error' do
          expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
        end
      end

      context 'when other exceptions happened' do
        let(:status) { :error }
        let(:rc) { 'error' }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_raise(StandardError)
        end

        it 'raises error' do
          expect { subject }.to raise_error(StandardError)
        end
      end

      context 'when response is failed' do
        let(:status) { :error }
        let(:rc) { '97' }
        let(:partner_response) { invalid_login_response.to_json }

        before do
          allow(Channel::Connection::Http).to receive_message_chain(:post, :body).and_return(partner_response)
        end

        it 'raise error' do
          expect { subject }.to raise_error(::Exceptions::PartnerIssue, 'Fail to retrieve session key for Tektaya')
        end
      end
    end

    context 'when buyer type is unknown' do
      subject { described_class.new('somebuyer').request }

      before do
        expect(Observer).not_to receive(:histogram)
      end

      it 'raises validation error' do
        expect { subject }.to raise_error(::Exceptions::PartnerIssue, 'Invalid buyer type for Tektaya')
      end
    end
  end
end
