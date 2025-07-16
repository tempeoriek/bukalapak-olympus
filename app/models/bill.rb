class Bill < ApplicationRecord
  belongs_to :postpaid_transaction

  validates :bill_period, presence: true
  validates :penalty_fee, presence: true, numericality: { only_integer: true }
  validates :amount, presence: true, numericality: { only_integer: true }
end
