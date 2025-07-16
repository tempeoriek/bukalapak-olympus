class PdamAutoswitchGroup < ApplicationRecord
  include Postpaid::Constant

  has_many :members, foreign_key: 'autoswitch_group_id', class_name: 'PdamAutoswitchGroupMember'

  enum state: {
    deleted: -1,
    inactive: 0,
    active: 1
  }

  scope :not_deleted, -> { where(:state => [INACTIVE, ACTIVE]) }
end
