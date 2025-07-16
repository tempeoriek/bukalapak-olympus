FactoryBot.define do
  factory :bpjs_ketenagakerjaan_transaction, class: BpjsKetenagakerjaanTransaction do
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

    trait :bpu do
      customer_number '187101090793000901'
      customer_name 'NICO JULIAN'
    end

    trait :recurrent do
      template_detail_id 1
    end

    buyer_id 1
    invoice_id 1
    remote_transaction_id 1
    amount 14_000
    admin_charge 1_500
    customer_number '210800004501'
    customer_name 'JKP EMPAT'
    branch_name 'JAKARTA GROGOL'
    reference_number nil
    transaction_type 1
    partner 'ayoconnect'
    bpjs_tk_type 'bpu'
    bill_code '921083112662'
    payment_period 1
    start_bill_period '2021-08-27'
    end_bill_period '2021-09-26'
    bpjs_ketenagakerjaan_bills { build_list :bpjs_ketenagakerjaan_bill, 1 }
    unpaid_bills false
  end
end
