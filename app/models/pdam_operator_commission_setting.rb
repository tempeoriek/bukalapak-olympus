class PdamOperatorCommissionSetting < ApplicationRecord
  belongs_to :pdam_operator

  enum state: {
    inactive: 0,
    active: 1
  }

  validates :value, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :min_transaction_value, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :max_transaction_value, presence: true, numericality: { greater_than_or_equal_to: :min_transaction_value, only_integer: true }
  validates :state, presence: true, inclusion: { in: states.keys }
  validate :unique, on: :create

  def unique
    errors.add(:base, 'duplicate record') if PdamOperatorCommissionSetting.where(pdam_operator_id: pdam_operator_id).exists?
  end
end
