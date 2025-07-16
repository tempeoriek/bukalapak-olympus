class ElectricityPostpaidPartnersBalance < ApplicationRecord
  belongs_to :electricity_postpaid_partners, foreign_key: :electricity_postpaid_partners_id

  # disable STI
  self.inheritance_column = :_type_disabled

  enum type: {
    bukalapak: 1,
    mitra: 2,
    bukaconnect: 3
  }
end
