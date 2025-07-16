FactoryBot.define do
  factory :pdam_autoswitch_group_member_setting, class: PdamAutoswitchGroupMemberSetting do
    id 1
    autoswitch_group_member_id 1
    threshold_value 30
    threshold_min_trx 1
    threshold_period_in_seconds 15
    threshold_type 1
    threshold_state 1
  end
end
