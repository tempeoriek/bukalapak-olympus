# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa, type: :model do
  subject { described_class }

  describe '.description' do
    let(:expected_description) { '[REST-264] Toggle to enable circuit breaker on bpjs kesehatan on sepulsa partner' }

    subject { described_class.description }

     it { is_expected.to eq(expected_description) }
  end

  describe '.toggle_name' do
    let(:toggle_name) { 'olympus/toggle/circuit_breaker/bpjs_kesehatan/sepulsa' }

    subject { described_class.toggle_name }

     it { is_expected.to eq(toggle_name) }
  end
end
