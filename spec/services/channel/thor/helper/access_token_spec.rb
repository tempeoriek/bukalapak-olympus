require 'rails_helper'

class AccessTokenMock
  include Channel::Thor::Helpers::AccessToken
end

RSpec.describe Channel::Thor::Helpers::AccessToken do
  let(:oauth_url) { Channel::Config::THOR_AUTH_HOST + '/oauth2/token' }
  let(:access_token_key) { 'THOR_ACCESS_TOKEN' }
  let(:response_body) do
    {
      access_token: 'token.abc.def',
      expires_in: 1000,
      token_type: "bearer",
      scope: 'anything'
    }.with_indifferent_access
  end

  describe '.get_jwt_token' do
    subject { AccessTokenMock.new.get_jwt_token }

    before { Rails.cache.clear }

    context 'when success' do
      before do
        response = double
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
        allow(response).to receive(:body).and_return(response_body.to_json)
      end

      it 'should return generated jwt token' do
        expect { subject }.not_to raise_error
        expect(Rails.cache.read(access_token_key)).to eq(response_body[:access_token])
      end
    end

    context 'when response timeout' do
      before do
        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'should raise timeout error' do
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
      end
    end

    context 'with other errors' do
      before do
        allow(Channel::Connection::Http).to receive(:post).and_raise(StandardError.new('some errors'))
      end

      it 'should raise an error' do
        expect { subject }.to raise_error(StandardError)
      end
    end
  end

  describe '.refresh_jwt_token' do
    let(:invalid_token) { 'invalid.jwt.token' }
    subject { AccessTokenMock.new.refresh_jwt_token }

    before do
      Rails.cache.clear
      Rails.cache.write(access_token_key, invalid_token, expires_in: 1000)
    end

    context 'when success' do
      before do
        response = double
        allow(Channel::Connection::Http).to receive(:post).and_return(response)
        allow(response).to receive(:body).and_return(response_body.to_json)
      end

      it 'should return generated jwt token' do
        expect { subject }.not_to raise_error
        expect(Rails.cache.read(access_token_key)).not_to eq(invalid_token) # invalid token deleted
        expect(Rails.cache.read(access_token_key)).to eq(response_body[:access_token]) # write new token
      end
    end

    context 'when get an error while refreshing token' do
      before do
        allow(Channel::Connection::Http).to receive(:post).and_raise(RestClient::Exceptions::OpenTimeout)
      end

      it 'should raise timeout error and no token found in cache' do
        expect { subject }.to raise_error(RestClient::Exceptions::OpenTimeout)
        expect(Rails.cache.read(access_token_key)).to be_nil
      end
    end
  end
end
