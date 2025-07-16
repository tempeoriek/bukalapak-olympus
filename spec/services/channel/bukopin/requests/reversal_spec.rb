require "rails_helper"
require 'support/electricity_mocks'

RSpec.describe Channel::Bukopin::ElectricityPostpaid::Requests::Reversal, type: :helper do
  include_context "electricity_mocks"

  describe 'when Bukopin Request does Reversal' do
    def mock_observer
      expect(RedisOlympus).not_to receive(:set)
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product => nil, :status => anything, :response_code => '0000'
      )).and_return(true)
    end

    def assert_wrap_request
      expect(subject).to receive(:wrap_request)
      .with(track_id: track_id, buyer_type: buyer_type)
      .and_call_original
    end

    before do
      mock_bukopin_token
      mock_iso_connection(and_return: bukopin_reversal_iso_response)

      assert_wrap_request
      mock_observer

      allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true
    end

    subject { described_class.new(bukopin_payment_iso_request_obj, buyer_type: buyer_type, track_id: track_id) }

    let(:track_id) { 1 }

    context 'with NORMAL_BUYER_TYPE' do
      let(:buyer_type) { NORMAL_BUYER_TYPE }

      it 'should not raise error' do
        expect { subject.run! }.not_to raise_error
      end
    end

    context 'with AGENT_BUYER_TYPE' do
      let(:buyer_type) { AGENT_BUYER_TYPE }

      it 'should not raise error' do
        expect { subject.run! }.not_to raise_error
      end
    end
  end
end
