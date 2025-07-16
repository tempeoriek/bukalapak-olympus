# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReprocessingTransactionMap, type: :model do
  let(:reprocessing_transaction_map) { build_stubbed(:reprocessing_job) }

  describe 'validation' do
    it { expect(reprocessing_transaction_map.valid?).to eq (true) }
  end
end
