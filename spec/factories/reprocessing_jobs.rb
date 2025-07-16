# frozen_string_literal: true

FactoryBot.define do
  factory :reprocessing_job do
    job_type "pdam"
    stuck_transaction_date "2022-08-03 23:00:29"
    state 1
    triggered_by_user_id 1
    triggered_by_user_name "Ritxman"

    trait :processed do
      state 0
    end

    trait :succeeded do
      state 1
    end

    trait :failed do
      state 2
    end
  end
end
