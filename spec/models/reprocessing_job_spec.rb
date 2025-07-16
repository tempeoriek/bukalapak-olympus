# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReprocessingJob, type: :model do
  let(:job) { build_stubbed(:reprocessing_job) }

  describe 'validation' do
    it { expect(job.valid?).to eq (true) }
  end
end
