class PdamBill < ApplicationRecord
  belongs_to :pdam_transaction

  validates :penalty_fee, presence: true, numericality: { only_integer: true }
  validates :amount, presence: true, numericality: { only_integer: true }

  def usage
    before, after = cubication.split('-')
    after.to_i - before.to_i
  rescue
    0
  end

  def as_json(_options={})
    result = super(
      only: [
        :bill_period,
        :penalty_fee,
        :amount,
        :cubication,
        :tariff
      ]
    )
    result['usage'] = usage
    result
  end
end
