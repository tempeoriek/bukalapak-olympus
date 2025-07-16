FactoryBot.define do
  factory :pdam_recurrence_template_detail, class: PdamRecurrenceTemplateDetail do
    id 1
    customer_number '12345'
    customer_name 'BADRUN'
    operator_id 1
    buyer_id 1
    recursive_id 1
    association :operator, factory: :pdam_operator
  end
end
