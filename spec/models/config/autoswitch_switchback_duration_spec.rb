# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Config::AutoswitchSwitchbackDuration, type: :model do
  subject { described_class }

  describe 'O2OVPE-2703: .description' do
    let(:expected_description) { '[O2OVPE-2703] Autoswitch Switchback Duration' }

    subject { described_class.description }

    it { is_expected.to eq(expected_description) }
  end

  describe 'O2OVPE-2703: .config_name' do
    let(:config_name) { 'olympus/config/autoswitch-switchback-duration' }

    subject { described_class.config_name }

    it { is_expected.to eq(config_name) }
  end

  describe 'O2OVPE-2703: .get_duration_by_day' do
    before do
      allow(described_class).to receive(:config).and_return(config_hash)
      allow(Time).to receive(:now).and_return(current_time)
    end

    let(:config_hash) { { weekday: 30, weekend: 60 } }
    let(:default_duration) { 15 }

    context 'when the current day is a weekday' do
      let(:current_time) { Time.new(2024, 8, 5) } # Monday

      it 'returns the weekday duration from config' do
        expect(described_class.get_duration_by_day(default_duration)).to eq(30.minutes)
      end
    end

    context 'when the current day is a weekend' do
      let(:current_time) { Time.new(2024, 8, 10) } # Saturday

      it 'returns the weekend duration from config' do
        expect(described_class.get_duration_by_day(default_duration)).to eq(60.minutes)
      end
    end

    context 'when config does not have a specific duration' do
      let(:config_hash) { {} }

      context 'when the current day is a weekday' do
        let(:current_time) { Time.new(2024, 8, 5) } # Monday

        it 'returns the duration from default value' do
          expect(described_class.get_duration_by_day(default_duration)).to eq(default_duration.minutes)
        end
      end

      context 'when the current day is a weekend' do
        let(:current_time) { Time.new(2024, 8, 10) } # Saturday

        it 'returns the duration from default value' do
          expect(described_class.get_duration_by_day(default_duration)).to eq(default_duration.minutes)
        end
      end
    end
  end
end
