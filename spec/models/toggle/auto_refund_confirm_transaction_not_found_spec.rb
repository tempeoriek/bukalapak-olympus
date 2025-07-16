# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Toggle::AutoRefundConfirmTransactionNotFound, type: :model do
  subject { described_class }

  describe '.description' do
    let(:expected_description) { '[O2OVPD-1464] Toggle to enable auto refund transaction when confirm transaction not found' }

    subject { described_class.description }

    it { is_expected.to eq(expected_description) }
  end

  describe '.toggle_name' do
    let(:toggle_name) { 'olympus/toggle/auto_refund_confirm_transaction_not_found' }

    subject { described_class.toggle_name }

    it { is_expected.to eq(toggle_name) }
  end
end
