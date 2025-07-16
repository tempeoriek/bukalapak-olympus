class PdamAutoswitchGroupMember < ApplicationRecord
  include Postpaid::Constant

  enum state: {
    deleted: -1,
    inactive: 0,
    active: 1
  }

  belongs_to :pdam_autoswitch_group
  belongs_to :operator, foreign_key: 'operator_id', class_name: 'PdamOperator'
  has_many :settings, foreign_key: 'autoswitch_group_member_id', class_name: 'PdamAutoswitchGroupMemberSetting'

  scope :not_deleted, -> { where(:state => [INACTIVE, ACTIVE]) }
end
