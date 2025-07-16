
FactoryBot.define do
  factory :pdam_autoswitch_group, class: PdamAutoswitchGroup do
    id 1
    name "PDAM Denpasar"
    state 1

    trait :with_members do
      members { build_list :pdam_autoswitch_group_member, 2 }
    end

    trait :with_members_and_settings do
      members { build_list :pdam_autoswitch_group_member, 2, :with_settings }
    end

    trait :deleted do
      id 2
      state -1
    end

    trait :inactive do
      id 3
      state 0
    end
  end
end
