require "rails_helper"

RSpec.describe Channel::Visa::CyberSource::SearchTransaction, type: :model do

  let(:client_reference_information_code) { '20200620005708979735' }
  let(:result_found) {
    File.read('spec/fixtures/visa/cyber_source/search_transaction_found.json')
  }
  let(:result_not_found) {
    File.read('spec/fixtures/visa/cyber_source/search_transaction_not_found.json')
  }
  let(:result_error) {
    net_http_res = double('net http response', :to_hash => {"Status" => ["404 Not Found"]}, :code => '404')
    request = request_double(url: 'http://example.com/', method: method)
    RestClient::Response.create(nil, net_http_res, request)
  }
  let(:api_protocol) {
    subject.send(:api_protocol)
  }

  subject {
    described_class.new(
      client_reference_information_code: client_reference_information_code
    )
  }

  describe '#url' do
    it { expect(subject.url).to eq "#{api_protocol}://#{Channel::Config::VISA_CYBS_API_HOST}/#{described_class::PATH}" }
  end

  describe '#payload' do
    it { expect(subject.payload).to include(:timezone, :query, :sort) }
    it "payload[:timezone] not empty" do
      expect(subject.payload[:timezone]).not_to be_empty
    end
    it "payload[:query] not empty" do
      expect(subject.payload[:query]).not_to be_empty
    end
    it "payload[:sort] not empty" do
      expect(subject.payload[:sort]).not_to be_empty
    end
  end

  describe '#send_request' do
    context 'success' do
      before {
        allow(Channel::Connection::Http)
          .to receive(:post)
          .with(kind_of(String), nil, kind_of(String), kind_of(Hash), kind_of(Hash))
          .and_return(result_found)
      }
      it { expect{ subject.send_request }.not_to raise_error }
    end

    context 'failed' do
      before {
        allow(Channel::Connection::Http)
          .to receive(:post)
          .with(kind_of(String), nil, kind_of(String), kind_of(Hash), kind_of(Hash))
          .and_return(result_not_found)
      }
      it { expect{ subject.send_request }.not_to raise_error }
    end

    context 'error' do
      before {
        allow(Channel::Connection::Http)
          .to receive(:post)
          .with(kind_of(String), nil, kind_of(String), kind_of(Hash), kind_of(Hash))
          .and_raise(RestClient::Exception.new('404 Not Found'))
      }
      it { expect{ subject.send_request }.to raise_error(RestClient::Exception) }
    end
  end
end
