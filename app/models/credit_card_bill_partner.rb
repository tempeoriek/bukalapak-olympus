class CreditCardBillPartner < ApplicationRecord
  include Postpaid::Constant

  belongs_to :credit_card_biller

  enum state: {
    deleted: -1,
    inactive: 0,
    active: 1
  }

  belongs_to :credit_card_biller

  validates :name, presence: true
  validates :terms_and_conditions, presence: true
  validates :bukalapak_admin_charge, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :partner_admin_charge, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :credit_card_biller_id, presence: true

  scope :not_deleted, -> { where(:state => [INACTIVE, ACTIVE]) }

  def admin_charge
    bukalapak_admin_charge + partner_admin_charge
  end

  def biller
    credit_card_biller
  end
end
