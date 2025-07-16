require "rails_helper"
require 'support/electricity_mocks'

RSpec.describe Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry, type: :helper do
  include_context "electricity_mocks"

  describe 'when Bukopin Request does Inquiry' do
    let(:timeout) { 30 }
    let(:track_id) { 1 }
    let(:buyer_type) { NORMAL_BUYER_TYPE }
    let(:bukopin_unique_key) { Channel::Bukopin::ElectricityPostpaid::Constants::BUKOPIN_UNIQUE_NUMBER_KEY }

    before do
      mock_bukopin_stan
      mock_bukopin_token
      expect(subject).to receive(:wrap_request)
        .with(read_timeout: timeout, track_id: track_id, buyer_type: buyer_type)
        .and_call_original
      mock_iso_connection(and_return: bukopin_inquiry_iso_response)
      expect(RedisOlympus).to receive(:set).with(kind_of(String), "0000", hash_including(:ex))
      expect(Observer).to receive(:histogram).with(kind_of(Symbol), kind_of(Float), hash_including(
        :action, :partner, :product, :biller_product => nil, :status => anything, :response_code => '0000'
      )).and_return(true)
    end

    subject { described_class.new(customer_number, track_id: track_id, read_timeout: timeout, buyer_type: buyer_type) }

    context 'with Normal Buyer' do
      before do
        allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return false
      end
      it 'should not raise error' do
        expect { subject.run! }.not_to raise_error
      end
    end

    context 'with Agent Buyer' do
      let(:buyer_type) { AGENT_BUYER_TYPE }
      let(:bukopin_unique_key) { Channel::Bukopin::ElectricityPostpaid::Constants::BUKOPIN_UNIQUE_NUMBER_KEY_BMI }

      before do
        allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return true
      end

      it 'should not raise error' do
        expect { subject.run! }.not_to raise_error
      end
    end
  end

  describe 'when fail to inquiry' do
    let(:timeout) { 30 }
    let(:track_id) { 1 }
    let(:buyer_type) { NORMAL_BUYER_TYPE }

    subject { described_class.new(customer_number, track_id: track_id, read_timeout: timeout, buyer_type: buyer_type) }

    context 'when raising error' do
      before do
        allow(Toggles::BukopinMitraAuth).to receive(:active?).and_return false
      end

      context 'mapped errors' do
        let(:failed_response) do
          {
            status: 'failed',
            response_code: '0014',
            message: 'Inkuiri Gagal'
          }
        end

        before { allow(subject).to receive(:wrap_request).and_return(failed_response) }

        it 'should raise error with error code 18117' do
          expect { subject.run! }.to raise_error { |error|
            expect(error).to be_a(::Exceptions::UnregisteredNumber)
            expect(error.error_code).to eq 18117
          }
        end
      end

      context 'unmapped errors' do
        let(:failed_response) do
          {
            status: 'failed',
            response_code: '0099',
            message: 'Inkuiri Gagal'
          }
        end

        before { allow(subject).to receive(:wrap_request).and_return(failed_response) }

        it 'should raise error with error code 18209' do
          expect { subject.run! }.to raise_error { |error|
            expect(error).to be_a(::Exceptions::Bukopin::Inquiry)
            expect(error.message).to eq failed_response[:message]
            expect(error.error_code).to eq 18209
          }
        end
      end
    end
  end
end
