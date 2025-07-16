require "rails_helper"
require 'support/electricity_mocks'

RSpec.describe Channel::Bukopin::ElectricityPostpaid::Requests::Network, type: :helper do
  include_context "electricity_mocks"

  describe 'when Bukopin Request does Inquiry' do
    let(:log_excluding_keys) { %i[raw_payload raw_response response] }
    let(:max_retry_count) { 0 }
    let(:buyer_type) { NORMAL_BUYER_TYPE }
    let(:network_action_code) { Channel::Bukopin::ElectricityPostpaid::Constants::NetworkCodes::GET_KEY }

    def expect_wrap_request
      expect(subject).to receive(:wrap_request)
      .with(log_excluding_keys: log_excluding_keys, max_retry_count: max_retry_count, buyer_type: buyer_type)
      .and_call_original
    end

    before do
      mock_bukopin_token
      mock_iso_connection(and_return: bukopin_network_iso_response)

      expect_wrap_request
    end

    subject { described_class.new(network_action_code, buyer_type) }

    context 'with NORMAL_BUYER_TYPE' do
      it 'should not raise error' do
        expect(RedisOlympus).not_to receive(:set)
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product => nil, :status => anything, :response_code => '0000'
        )).and_return(true)
        allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true

        expect { subject.run! }.not_to raise_error
      end

      context 'when network error - timeout to pln' do
        let(:bukopin_network_iso_response) {
          #                                           0068 (bit 39)
          '281000100000838100002020010815162707441126000681010000000BUKALAPAK048645F0C7B1F8C3192C9A6DC3F002F779C29F2F423646D0A82'
        }
        it {
          expect(RedisOlympus).not_to receive(:set)
          expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
            :action, :partner, :product, :biller_product => nil, :status => anything, :response_code => '0068'
          )).and_return(true)
          allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true
          expect { subject.run! }.to raise_error(Exceptions::Bukopin::Network)
        }
      end
    end

    context 'with AGENT_BUYER_TYPE' do
      let(:buyer_type) { AGENT_BUYER_TYPE }

      before do
        allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true
      end

      it 'should not raise error' do
        expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
          :action, :partner, :product, :biller_product => nil, :status => anything, :response_code => '0000'
        )).and_return(true)

        expect { subject.run! }.not_to raise_error
      end
    end

  end
end
