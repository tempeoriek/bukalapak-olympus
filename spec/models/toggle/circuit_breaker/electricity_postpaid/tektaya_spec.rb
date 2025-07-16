require 'rails_helper'

RSpec.describe Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya, type: :model do
  subject { described_class }

  describe '.description' do
    let(:expected_description) { '[REST-686] Toggle to enable circuit breaker on electricity postpaid product for tektaya partner' }

    subject { described_class.description }

     it { is_expected.to eq(expected_description) }
  end

  describe '.toggle_name' do
    let(:toggle_name) { 'olympus/toggle/circuit_breaker/electricity_postpaid/tektaya' }

    subject { described_class.toggle_name }

     it { is_expected.to eq(toggle_name) }
  end
end
