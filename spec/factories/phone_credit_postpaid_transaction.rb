FactoryBot.define do
  factory :phone_credit_postpaid_transaction, class: PhoneCreditPostpaidTransaction do

    trait :pending do
      state 0
    end

    trait :processed do
      state 1
    end

    trait :succeeded do
      state 2
    end

    trait :failed do
      state 3
    end

    trait :paid do
      state 4
    end

    trait :partner_succeeded do
      state 5
    end

    trait :partner_failed do
      state 6
    end

    trait :expired do
      state 7
    end

    trait :cancelled do
      state 8
    end

    trait :agent do
      transaction_type 1
    end

    buyer_id 1
    provider_id 1
    remote_transaction_id 30
    reference_number '2203267'
    customer_name "INDAH PRAWITA HAPSARI"
    phone_number "081234000001"
    outstanding_bill 1
    start_bill_period "2018-01-01"
    end_bill_period "2018-01-01"
    bill_amount 51000
    partner_admin_charge 1000
    bukalapak_admin_charge 500
    total_amount 52500
    partner 'sepulsa'
    transaction_type 0
  end
end
