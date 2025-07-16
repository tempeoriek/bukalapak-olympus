FactoryBot.define do
  factory :pdam_operator_commission_setting do
    association :pdam_operator
    value { 10 }
    state { 'active' }
    min_transaction_value { 1_000 }
    max_transaction_value { 1_000_000 }
  end
end
