FactoryBot.define do
  factory :sievex_action_log, class: SievexActionLog do
    entity_id 1
    entity_type 'credit_card_bill_transaction'
    actor 'system'
    reason 'Daily Limit Exceeded'
  end
end
