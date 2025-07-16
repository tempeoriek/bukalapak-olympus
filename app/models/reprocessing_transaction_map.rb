# frozen_string_literal: true

class ReprocessingTransactionMap < ApplicationRecord
  belongs_to :reprocessing_job, class_name: '::ReprocessingJob', foreign_key: 'job_id'
  belongs_to :pdam_transaction, class_name: '::PdamTransaction', foreign_key: 'transaction_id'

  validates :job_id, presence: true, numericality: { only_integer: true }
  validates :transaction_id, presence: true, numericality: { only_integer: true }
end
