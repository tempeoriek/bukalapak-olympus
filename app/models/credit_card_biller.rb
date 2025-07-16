class CreditCardBiller < ApplicationRecord
  include Postpaid::Constant

  has_many :credit_card_bill_partner

  validates :name, presence: true
  validates :image_url, presence: true

  enum active: {
    deleted: -1,
    inactive: 0,
    active: 1
  }

  scope :not_deleted, -> { where(:active => [INACTIVE, ACTIVE]) }

  def biller_code
    partner.biller_code
  end

  def admin_charge
    partner.admin_charge
  end

  def bukalapak_admin_charge
    partner.bukalapak_admin_charge
  end

  def partner_admin_charge
    partner.partner_admin_charge
  end

  def partners
    credit_card_bill_partner
  end

  def partner
    credit_card_bill_partner.find_by_state('active')
  end

  def as_json(_options={})
    result = super(
      only: [
        :id,
        :name,
        :image_url
      ]
    )
    result['terms_and_conditions'] = partner.terms_and_conditions
    result['admin_charge'] = partner.admin_charge
    result
  end
end
