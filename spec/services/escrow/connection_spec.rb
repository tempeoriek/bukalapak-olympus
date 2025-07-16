require 'rails_helper'
require 'json'

RSpec.describe Escrow::Connection, type: :model do
  let(:url) { 'www.test.co.id/test' }
  let(:payload) { { foo: 'bar' } }
  let(:included_headers) { { 'BL-Service': 'olympus' } }
  subject { described_class }

  context '.get' do
    it 'header include BL-Service' do
      expect(::RestClient::Request).to receive(:execute).with(hash_including(headers: hash_including(included_headers))).and_return true
      subject.get(url)
    end
  end

  context '.post' do
    it 'header include BL-Service' do
      expect(::RestClient::Request).to receive(:execute).with(hash_including(headers: hash_including(included_headers))).and_return true
      subject.post(url, payload)
    end
  end

  context '.patch' do
    it 'header include BL-Service' do
      expect(::RestClient::Request).to receive(:execute).with(hash_including(headers: hash_including(included_headers))).and_return true
      subject.patch(url, payload)
    end
  end
end
