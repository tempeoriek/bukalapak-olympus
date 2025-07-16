class BpjsKetenagakerjaanPartner < ApplicationRecord
  enum state: {
    inactive: 0,
    active: 1
  }

  def admin_charge
    bukalapak_admin_charge + partner_admin_charge
  end
end