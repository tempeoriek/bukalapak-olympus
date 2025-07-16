class PhoneCreditProvider < ApplicationRecord
  include Postpaid::Constant

  enum partner: {
    sepulsa: 0
  }

  enum active: {
    deleted: -1,
    inactive: 0,
    active: 1
  }

  scope :not_deleted, -> { where(:active => [INACTIVE, ACTIVE]) }
end
