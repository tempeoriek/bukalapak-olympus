FactoryBot.define do
  factory :bill, class: Bill do
    bill_period Date.current.beginning_of_month
    due_date Date.current.end_of_month - 10.day
    penalty_fee 1_000
    amount 88_500
    previous_meter 27_135
    current_meter 27_280
  end
end
