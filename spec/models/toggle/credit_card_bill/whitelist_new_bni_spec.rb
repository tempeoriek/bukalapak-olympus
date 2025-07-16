# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Toggle::CreditCardBill::WhitelistNewBNI, type: :model do
  subject { described_class }

  describe '.description' do
    let(:expected_description) { '[REST-2947] Toggle to whitelist for new BNI partner' }

    subject { described_class.description }

     it { is_expected.to eq(expected_description) }
  end

  describe '.toggle_name' do
    let(:toggle_name) { 'olympus/toggle/credit_card_bill/whitelist_new_bni' }

    subject { described_class.toggle_name }

     it { is_expected.to eq(toggle_name) }
  end
end
