class PdamAutoswitchGroupMemberSetting < ApplicationRecord
  
  belongs_to :pdam_autoswitch_group_member

  enum threshold_type: {
    processed_count: 0,
    refund_rate: 1
  }

  enum threshold_state: {
    inactive: 0,
    active: 1
  }

  def self.is_type_valid(type)
    return threshold_types.keys.include?(type)
  end

  def self.is_state_valid(state)
    return threshold_states.keys.include?(state)
  end
end
