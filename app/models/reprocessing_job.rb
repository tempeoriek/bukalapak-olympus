# frozen_string_literal: true

class ReprocessingJob < ApplicationRecord
  enum state: {
    processed: 0,
    succeeded: 1,
    failed: 2
  }

  validates :job_type, presence: true
  validates :triggered_by_user_id, presence: true, numericality: { only_integer: true }
  validates :triggered_by_user_name, presence: true

end
