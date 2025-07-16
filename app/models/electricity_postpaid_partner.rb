class ElectricityPostpaidPartner < ApplicationRecord
  include Postpaid::Constant

  has_many :electricity_postpaid_partners_balances, :foreign_key => :electricity_postpaid_partners_id

  enum state: {
    inactive: 0,
    active: 1
  }

  enum partner_type: {
    'normal': 0,
    'collecting-agent': 1
  }

  def admin_charge
  	bukalapak_admin_charge + partner_admin_charge
  end

  def bukaconnect_partner?
    name.include?(BUKACONNECT)
  end
end
