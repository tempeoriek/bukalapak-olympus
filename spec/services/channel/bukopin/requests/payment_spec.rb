require "rails_helper"
require 'support/electricity_mocks'

RSpec.describe Channel::Bukopin::ElectricityPostpaid::Requests::Payment, type: :helper do
  include_context "electricity_mocks"

  describe 'when Bukopin Request does Payment' do
    def mock_observer
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product => nil, :status => status, :response_code => rc
      )).and_return(true)
    end

    def assert_wrap_request
      expect(subject).to receive(:wrap_request)
      .with(track_id: track_id, buyer_type: buyer_type)
      .and_call_original
    end

    before do
      mock_bukopin_token
      mock_iso_connection(and_return: bukopin_payment_iso_response)
      mock_observer

      assert_wrap_request
      allow_any_instance_of(described_class).to receive(:sign_on).and_return true
    end

    let(:track_id) { 1 }

    subject { described_class.new(bukopin_inquiry_request_response, buyer_type: buyer_type, track_id: track_id) }

    context 'with NORMAL_BUYER_TYPE' do
      let(:buyer_type) { NORMAL_BUYER_TYPE }
      let(:status) { :error }

      before do
        allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true
      end

      context 'when normal flow' do
        let(:rc) { '0000' }
        let(:status) { :success }

        it 'should not raise error' do
          expect(RedisOlympus).to receive(:set).with(kind_of(String), "0000", hash_including(:ex))

          expect { subject.run! }.not_to raise_error
        end
      end

      context 'when connection unauthorized' do
        let(:bukopin_payment_iso_response) {
          #                                           0011 (bit 39)
          '281000100000838100002020010815162707441126000111010000000BUKALAPAK048645F0C7B1F8C3192C9A6DC3F002F779C29F2F423646D0A82'
        }
        let(:rc) { '0011' }

        it {
          expect(RedisOlympus).to receive(:set).with(kind_of(String), "0011", hash_including(:ex))
          allow_any_instance_of(described_class).to receive(:sign_on).and_return true
          expect { subject.run! }.to raise_error(Exceptions::Bukopin::Unauthorized)
        }
      end

      context 'when invalid security data' do
        let(:bukopin_payment_iso_response) {
          #                                           0096 (bit 39)
          '281000100000838100002020010815162707441126000961010000000BUKALAPAK048645F0C7B1F8C3192C9A6DC3F002F779C29F2F423646D0A82'
        }
        let(:rc) { '0096' }

        it {
          expect(RedisOlympus).to receive(:set).with(kind_of(String), "0096", hash_including(:ex))
          allow(::Keystore).to receive(:expire).and_return true
          expect { subject.run! }.to raise_error(Exceptions::Bukopin::InvalidSecurityData)
        }
      end

      context 'when socket timeout' do
        let(:rc) { :timeout }

        it {
          expect(RedisOlympus).to receive(:set).with(kind_of(String), "unknown_response", hash_including(:ex))
          allow(::Channel::Connection::Iso8583).to receive(:send).and_raise Exceptions::SocketConnectionTimeout
          expect { subject.run! }.to raise_error(Exceptions::SocketConnectionTimeout)
        }
      end

      context 'when no result' do
        let(:rc) { '0000' }
        let(:status) { :success }

        it {
          expect(RedisOlympus).to receive(:set).with(kind_of(String), "0000", hash_including(:ex))
          allow_any_instance_of(::Channel::Bukopin::ElectricityPostpaid::IsoMessage).to receive(:build_hash).and_return nil
          expect { subject.run! }.to raise_error(Exceptions::Bukopin::Payment)
        }
      end
    end

    context 'with AGENT_BUYER_TYPE' do
      let(:buyer_type) { AGENT_BUYER_TYPE }
      let(:rc) { '0000' }
      let(:status) { :success }

      before do
        allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true
      end

      it 'should not raise error' do
        expect(RedisOlympus).to receive(:set).with(kind_of(String), "0000", hash_including(:ex))
        expect { subject.run! }.not_to raise_error
      end
    end
  end
end
