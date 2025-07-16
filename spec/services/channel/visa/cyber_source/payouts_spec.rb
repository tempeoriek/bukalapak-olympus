require "rails_helper"

RSpec.describe Channel::Visa::CyberSource::Payouts, type: :model do

  let(:token) { '7010000000112271111' }
  let(:amount) { '500000' }
  let(:result_accepted) {
    File.read('spec/fixtures/visa/cyber_source/payouts_accepted.json')
  }
  let(:result_declined) {
    File.read('spec/fixtures/visa/cyber_source/payouts_declined.json')
  }
  let(:api_protocol) {
    subject.send(:api_protocol)
  }

  subject {
    described_class.new(
      token: token,
      amount: amount
    )
  }

  describe '#url' do
    it { expect(subject.url).to eq "#{api_protocol}://#{Channel::Config::VISA_CYBS_API_HOST}/#{described_class::PATH}" }
  end

  describe '#payload' do
    it {
      expect(subject.payload).to include(
        'clientReferenceInformation',
        'orderInformation',
        'merchantInformation',
        'paymentInformation'
      )
    }
    it "payload['clientReferenceInformation']['code'] not empty" do
      expect(subject.payload['clientReferenceInformation']['code']).not_to be_empty
    end
    it "payload['orderInformation']['amountDetails']['totalAmount'] not empty" do
      expect(subject.payload['orderInformation']['amountDetails']['totalAmount']).not_to be_empty
    end
    it "payload['orderInformation']['amountDetails']['currency'] is IDR" do
      expect(subject.payload['orderInformation']['amountDetails']['currency']).to eq 'IDR'
    end
    it "payload['merchantInformation']['merchantDescriptor']['name'] is 'Bukalapak'" do
      expect(subject.payload['merchantInformation']['merchantDescriptor']['name']).to eq 'Bukalapak'
    end
    it "payload['paymentInformation']['customer']['customerId'] not empty" do
      expect(subject.payload['paymentInformation']['customer']['customerId']).not_to be_empty
    end
  end

  describe '#reference_code' do
    it {
      expect(subject.reference_code).to eq subject.payload['clientReferenceInformation']['code']
    }
  end

  describe '#send_request' do
    context 'success' do
      before {
        allow(Channel::Connection::Http)
          .to receive(:post)
          .with(kind_of(String), nil, kind_of(String), kind_of(Hash), kind_of(Hash))
          .and_return(result_accepted)
      }
      it { expect{ subject.send_request }.not_to raise_error }
    end

    context 'failed' do
      before {
        allow(Channel::Connection::Http)
          .to receive(:post)
          .with(kind_of(String), nil, kind_of(String), kind_of(Hash), kind_of(Hash))
          .and_return(result_declined)
      }
      it { expect{ subject.send_request }.not_to raise_error }
    end

    context 'error' do
      before {
        allow(Channel::Connection::Http)
          .to receive(:post)
          .with(kind_of(String), nil, kind_of(String), kind_of(Hash), kind_of(Hash))
          .and_raise(RestClient::Exception.new('Connection timeout'))
      }
      it { expect{ subject.send_request }.to raise_error(RestClient::Exception) }
    end
  end
end
