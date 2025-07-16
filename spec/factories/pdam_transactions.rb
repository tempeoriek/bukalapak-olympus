FactoryBot.define do
  factory :pdam_transaction_with_bill, class: PdamTransaction do
    transient do
      bills_count 2
    end

    trait :pending do
      state 0
    end

    trait :processed do
      state 1
      processed_at Time.now
    end

    trait :processed_three_hours_ago do
      state 1
      processed_at Time.now - 3.hours
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

    trait :recurrent do
      template_detail_id 1
    end

    trait :without_partner_transaction_id do
      partner_transaction_id nil
    end

    trait :agent do
      transaction_type 1
    end

    trait :partner_vsi_thor do
      partner 'vsi_thor'
    end

    trait :partner_mkm_thor do
      partner 'mkm_thor'
    end

    trait :address_present do
      address 'This address'
    end

    buyer_id 1
    customer_name "Putin"
    customer_number "1998800007"
    start_bill_period "2012-01-01"
    end_bill_period "2012-01-15"
    amount 12_610
    penalty_fee 0
    bukalapak_admin_charge { Test::BUKALAPAK_ADMIN_CHARGE * bills_count }
    partner_admin_charge { Test::PARTNER_ADMIN_CHARGE * bills_count }
    remote_transaction_id 33
    association :pdam_operator
    invoice_id 1
    partner "sepulsa"
    partner_transaction_id "1234"
    transaction_type 0
    pdam_bills { build_list :pdam_bill, bills_count }
    details do
      { }
    end
  end
end
