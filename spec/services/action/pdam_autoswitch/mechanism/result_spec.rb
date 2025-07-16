require "rails_helper"

RSpec.describe Action::PdamAutoswitch::Mechanism::Result, type: :model do
  let(:processed_count_setting) { build_stubbed(:pdam_autoswitch_group_member_setting, threshold_type: 'processed_count', threshold_value: 30, threshold_min_trx: 5, threshold_period_in_seconds: 15, threshold_state: 'active') }
  let(:refund_rate_setting) { build_stubbed(:pdam_autoswitch_group_member_setting, threshold_type: 'refund_rate', threshold_value: 50, threshold_min_trx: 5, threshold_period_in_seconds: 15, threshold_state: 'active') }

  subject { described_class.new(params) }

  before do
    allow(::Toggle::PdamAutoswitch)
      .to receive(:active?)
      .and_return(true)
  end

  describe 'O2OVPE-844: #run!' do
    context 'when inactive' do
      let(:params) {
        {
          last_timestamp: Time.now,
          total_count: 100,
          total_failed: 100,
          setting: processed_count_setting.tap { |s| s.threshold_state = 'inactive' },
        }
      }
      it 'returns noop' do
        expect(subject.evaluate!).to eq(:noop)
      end
    end

    context 'when expired' do
      let(:params) {
        {
          last_timestamp: Time.now - processed_count_setting.threshold_period_in_seconds.seconds - 1.second,
          total_count: 100,
          total_failed: 100,
          setting: processed_count_setting,
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
          total_count: processed_count_setting.threshold_min_trx - 1,
          total_failed: 0,
          setting: processed_count_setting,
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
          total_count: processed_count_setting.threshold_value + 1,
          total_failed: processed_count_setting.threshold_value + 1,
          setting: processed_count_setting,
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
          setting: refund_rate_setting,
        }
      }
      it 'returns block' do
        expect(subject.evaluate!).to eq(:block)
      end
    end
  end
end
