# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Toggle::PdamAutoswitch, type: :model do
  subject { described_class }

  describe '.description' do
    let(:expected_description) { 'Toggle to enable PDAM autoswitch' }

    subject { described_class.description }

    it { is_expected.to eq(expected_description) }
  end

  describe '.toggle_name' do
    let(:toggle_name) { 'olympus/toggle/pdam_autoswitch' }

    subject { described_class.toggle_name }

    it { is_expected.to eq(toggle_name) }
  end
end
