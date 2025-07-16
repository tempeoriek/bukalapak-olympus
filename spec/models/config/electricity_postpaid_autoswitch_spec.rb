# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Config::ElectricityPostpaidAutoswitch, type: :model do
  subject { described_class }

  describe '.description' do
    let(:expected_description) { '[O2OVPE-1674] Electricity Postpaid Autoswitch' }

    subject { described_class.description }

    it { is_expected.to eq(expected_description) }
  end

  describe '.config_name' do
    let(:config_name) { 'olympus/config/electricity-postpaid-autoswitch' }

    subject { described_class.config_name }

    it { is_expected.to eq(config_name) }
  end
end
