require "rails_helper"

RSpec.describe Channel::Visa::CyberSource::DeleteToken, type: :model do

  let(:token) { '7010000000112271111' }

  let(:success_response) {
    net_http_res = double('net http response', :to_hash => {"Status" => ["204 No Content"]}, :code => '204')
    request = request_double(url: 'http://example.com/', method: method)
    RestClient::Response.create('', net_http_res, request)
  }

  let(:failed_response) {
    net_http_res = double('net http response', :to_hash => {"Status" => ["410 Gone"]}, :code => '410')
    request = request_double(url: 'http://example.com/', method: method)
    body = {
      "errors": [
        {
          "type": "notAvailable",
          "message": "Token not available"
        }
      ]
    }.to_json
    RestClient::Response.create(body, net_http_res, request)
  }

  let(:api_protocol) {
    subject.send(:api_protocol)
  }

  subject {
    described_class.new(token: token)
  }

  describe '#path' do
    it { expect(subject.path).to eq described_class::PATH }
  end

  describe '#url' do
    context 'with token' do
      it { expect(subject.url).to eq "#{api_protocol}://#{Channel::Config::VISA_CYBS_API_HOST}/#{described_class::PATH}/#{token}" }
    end
    context 'without token' do
      it { expect(subject.url(exclude_token: true)).to eq "#{api_protocol}://#{Channel::Config::VISA_CYBS_API_HOST}/#{described_class::PATH}" }
    end
  end

  describe '#send_request' do
    let(:method) { :delete }

    context 'success' do
      before {
        allow(Channel::Connection::Http)
          .to receive(:delete)
          .with(kind_of(String), nil, kind_of(Hash), kind_of(Hash))
          .and_return(success_response)
      }
      it { expect(subject.send_request).to eq true }
    end

    context 'failed' do
      before {
        allow(Channel::Connection::Http)
          .to receive(:delete)
          .with(kind_of(String), nil, kind_of(Hash), kind_of(Hash))
          .and_return(failed_response)
      }
      it { expect(subject.send_request).to eq false }
    end

    context 'error' do
      before {
        allow(Channel::Connection::Http)
          .to receive(:delete)
          .with(kind_of(String), nil, kind_of(Hash), kind_of(Hash))
          .and_raise(RestClient::Exception.new('Connection timeout'))
      }
      it { expect{ subject.send_request }.to raise_error(RestClient::Exception) }
    end
  end
end
