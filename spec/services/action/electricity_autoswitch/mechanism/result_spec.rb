require "rails_helper"

RSpec.describe Action::ElectricityAutoswitch::Mechanism::Result, type: :model do
  
  let(:processed_count_threshold) { {
    type: "processed_count",
    value: 30,
    min_trx: 5,
    period_in_seconds: 15,
    status: "active"
  } }

  let(:refund_rate_threshold) { {
    type: "refund_rate",
    value: 30,
    min_trx: 5,
    period_in_seconds: 15,
    status: "active"
  } }

  subject { described_class.new(params) }

  describe 'O2OVPE-1674: #run!' do
    context 'when inactive' do
      let(:params) {
        {
          last_timestamp: Time.now,
          total_count: 100,
          total_failed: 100,
          threshold: processed_count_threshold.tap { |t| t[:status] = 'inactive' },
        }
      }
      it 'returns noop' do
        expect(subject.evaluate!).to eq(:noop)
      end
    end

    context 'when expired' do
      let(:params) {
        {
          last_timestamp: Time.now - processed_count_threshold[:period_in_seconds].seconds - 1.second,
          total_count: 100,
          total_failed: 100,
          threshold: processed_count_threshold,
        }
      }
      it 'returns allow' do
        expect(subject.evaluate!).to eq(:allow)
      end
    end

    context 'when insufficient count' do
      let(:params) {
        {
          last_timestamp: 20.seconds.ago,
          total_count: processed_count_threshold[:min_trx] - 1,
          total_failed: 0,
          threshold: processed_count_threshold,
        }
      }
      it 'returns allow' do
        expect(subject.evaluate!).to eq(:allow)
      end
    end

    context 'when processed count threshold exceeded' do
      let(:params) {
        {
          last_timestamp: Time.now,
          total_count: processed_count_threshold[:value] + 1,
          total_failed: processed_count_threshold[:value] + 1,
          threshold: processed_count_threshold,
        }
      }
      it 'returns block' do
        expect(subject.evaluate!).to eq(:block)
      end
    end

    context 'when refund rate threshold exceeded' do
      let(:params) {
        {
          last_timestamp: Time.now,
          total_count: 10,
          total_failed: 5,
          threshold: refund_rate_threshold,
        }
      }
      it 'returns block' do
        expect(subject.evaluate!).to eq(:block)
      end
    end
  end
end
