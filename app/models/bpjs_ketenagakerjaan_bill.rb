class BpjsKetenagakerjaanBill < ApplicationRecord
  belongs_to :bpjs_ketenagakerjaan_transaction

  validates :amount, presence: true, numericality: { only_integer: true }

end
