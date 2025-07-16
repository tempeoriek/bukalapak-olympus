require 'rails_helper'

RSpec.describe Toggle::CircuitBreaker::Thor, type: :model do
  subject { described_class }

  describe 'O2OVPD-600: .description' do
    let(:expected_description) { '[O2OVPD-600] Toggle to enable circuit breaker on all product for thor partner' }

    subject { described_class.description }

    it { is_expected.to eq(expected_description) }
  end

  describe 'O2OVPD-600: .toggle_name' do
    let(:toggle_name) { 'olympus/toggle/circuit_breaker/thor' }

    subject { described_class.toggle_name }

    it { is_expected.to eq(toggle_name) }
  end
end
