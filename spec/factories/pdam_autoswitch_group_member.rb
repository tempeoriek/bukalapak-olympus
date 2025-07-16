FactoryBot.define do
  factory :pdam_autoswitch_group_member, class: PdamAutoswitchGroupMember do
    id 1
    association :operator, factory: :pdam_operator
    autoswitch_group_id 1
    state 1

    trait :deleted do
      id 2
      state -1
    end

    trait :with_settings do
      after(:create) do |member|
        build_list(:pdam_autoswitch_group_member_setting, 2, autoswitch_group_member_id: member.id)
      end
    end
  end
end
