# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Channel::NewBNI::Request::Base, type: :model do
  describe '[REST-2537] #retrieve_access_token' do
    let(:token_key) { 'new_bni_access_token' }
    let(:token) { 'some_old_token' }
    let(:access_token_result) do
      {
        access_token: 'V0nmtLdEfvkc2QmKfu5ycsfIttl84ge8P0G3yAV2HDv9VGFG8s2URa',
        token_type: 'Bearer',
        expires_in: 3600,
        scope: 'resource.WRITE resource.READ'
      }
    end

    subject { described_class.new.retrieve_access_token }

    context 'when the token is cached' do
      it 'returns token from cache' do
        expect(Keystore).to receive(:get).with(token_key).and_return(token)
        expect(subject).to eq token
      end
    end

    context 'when the token is not cached' do
      let(:raw_response) { double 'response' }

      it 'returns token from request and save to cache' do
        expect(Keystore).to receive(:get).with(token_key).and_return(nil)
        expect(Channel::Connection::Http).to receive(:post).and_return raw_response
        expect(raw_response).to receive(:body).and_return(access_token_result.to_json)
        expect(Keystore).to receive(:set).with(token_key, access_token_result[:access_token], access_token_result[:expires_in]).and_return(true)

        expect(subject).to eq access_token_result[:access_token]
      end
    end

    context 'when token is not cached but encounters error when request' do
      it 'returns token from request and save to cache' do
        expect(Keystore).to receive(:get).with(token_key).and_return(nil)
        expect(Channel::Connection::Http).to receive(:post).and_raise(StandardError)
        expect(Channel::Connection::Http).to receive(:post).at_least(5)

        expect { subject }.to raise_error(StandardError)
      end
    end
  end

  describe '[REST-2537] #generate_signature' do
    let(:headers) { described_class.new.send(:token_headers) }
    let(:payload) do
      {
        cardNum: '1234567890123456'
      }
    end

    subject { described_class.new.generate_signature(payload) }

    before do
      stub_const("#{described_class.to_s}::API_SECRET_KEY", 'somekey')
    end

    it 'decodes to a kind of JWT' do
      token_parts = subject.split('.')

      # validate JWT headers, payload, and signature respectively
      expect(token_parts[0]).to eq Base64.strict_encode64(headers.to_json).gsub('+', '-').gsub(/=+$/, '').gsub('/', '_')
      expect(token_parts[1]).to eq Base64.strict_encode64(payload.to_json).gsub('+', '-').gsub(/=+$/, '').gsub('/', '_')
      expect(token_parts[2]).to be_a(String)
    end
  end

  describe '[REST-2537] #metric_tags' do
    context 'when additional tags is provided' do
      let(:additional_tags) do
        { tag1: :action, tag2: :something }
      end

      let(:expected_tags) do
        {
          partner: :new_bni,
          product_type: :credit_card_bill
        }.merge(additional_tags)
      end

      subject { described_class.new.metric_tags(additional_tags) }

      it 'returns the metric tags with additional tag' do
        expect(subject).to eq expected_tags
      end
    end

    context 'when additional tags is not provided' do
      let(:expected_tags) do
        {
          partner: :new_bni,
          product_type: :credit_card_bill
        }
      end

      subject { described_class.new.metric_tags }

      it 'returns the metric tags without additional tag' do
        expect(subject).to eq expected_tags
      end
    end
  end

  describe '[REST-2537] #publish_log' do
    let(:message) do
      { action: :test, payload: { cardNum: '1234567890' } }
    end

    let(:expected_tags) { %W[credit_card_bill test partner new_bni] }
    let(:track_id) { 'some_track_id' }
    let(:context) { double 'context' }

    subject { described_class.new.publish_log(:test, message, track_id) }

    it 'logs to output' do
      expect_any_instance_of(::Context).to receive(:log_entry).with(message, expected_tags, { track_id: track_id }).and_return(context)
      expect(Logger2).to receive(:info).with(context)
      expect { subject }.not_to raise_error
    end
  end
end
