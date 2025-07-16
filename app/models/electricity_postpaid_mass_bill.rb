class ElectricityPostpaidMassBill < ApplicationRecord
  belongs_to :postpaid_transaction

  validates :postpaid_transaction_id, presence: true, uniqueness: true
  validates :mass_bill_id, presence: true, format: {
    with: /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i,
    message: 'Harus UUID atau nil'
  }
end
