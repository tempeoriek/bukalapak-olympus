require "rails_helper"

RSpec.describe Channel::Visa::CyberSource::Base, type: :model do

  let(:url) { 'http://example.com' }
  let(:profile_id) { 'C3396489-5C91-4188-987C-1BB5B9C3C687' }

  subject { described_class.new }

  before {
    allow_any_instance_of(described_class).to receive(:url).and_return url
    allow_any_instance_of(described_class).to receive(:payload).and_return ""
    allow(Channel::Connection::Http)
      .to receive(:get)
      .with(kind_of(String), nil, nil, kind_of(Hash), kind_of(Hash))
      .and_return true
    allow(Channel::Connection::Http)
      .to receive(:post)
      .with(kind_of(String), nil, kind_of(String), kind_of(Hash), kind_of(Hash))
      .and_return true
    allow(Channel::Connection::Http)
      .to receive(:delete)
      .with(kind_of(String), nil, kind_of(Hash), kind_of(Hash))
      .and_return true
  }

  describe '#get_headers' do

    let(:send_request) { subject.send_request }

    context 'http_method GET' do
      it 'headers key are correct' do
        stub_const("#{described_class.to_s}::HTTP_METHOD", :get)
        send_request
        headers_key = subject.send(:get_headers).keys
        expect(headers_key).to include(
          'Accept',
          'Content-Type',
          'User-Agent',
          'v-c-merchant-id',
          'Date',
          'Host',
          'Signature',
        )
      end
    end

    context 'http_method POST' do
      it 'headers key are correct' do
        stub_const("#{described_class.to_s}::HTTP_METHOD", :post)
        send_request
        headers_key = subject.send(:get_headers).keys
        expect(headers_key).to include(
          'Accept',
          'Content-Type',
          'User-Agent',
          'v-c-merchant-id',
          'Date',
          'Host',
          'Signature',
          'Digest'
        )
      end
    end

    context 'http_method DELETE' do
      it 'headers key are correct' do
        stub_const("#{described_class.to_s}::HTTP_METHOD", :delete)
        send_request
        headers_key = subject.send(:get_headers).keys
        expect(headers_key).to include(
          'Accept',
          'Content-Type',
          'User-Agent',
          'v-c-merchant-id',
          'Date',
          'Host',
          'Signature'
        )
      end

      context 'with PROFILE_ID' do
        it 'headers key are correct' do
          stub_const("#{described_class.to_s}::PROFILE_ID", profile_id)
          send_request
          headers_key = subject.send(:get_headers).keys
          expect(headers_key).to include(
            'Accept',
            'Content-Type',
            'User-Agent',
            'v-c-merchant-id',
            'Date',
            'Host',
            'Signature',
            'profile-id'
          )
        end
      end
    end
  end
end
