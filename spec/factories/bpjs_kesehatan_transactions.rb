FactoryBot.define do
  factory :bpjs_kesehatan_transaction, class: BpjsKesehatanTransaction do

    trait :pending do
      state 0
    end

    trait :processed do
      processed_at Time.now
      state 1
    end

    trait :succeeded do
      state 2
    end

    trait :failed do
      state 3
    end

    trait :recurrent do
      template_detail_id 1
    end

    trait :paid do
      state 4
    end

    trait :partner_succeeded do
      state 5
      reference_number '2023499580'
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

    trait :with_partner_transaction_id do
      partner_transaction_id 123654
    end

    trait :without_partner_transaction_id do
      partner_transaction_id nil
    end

    trait :agent do
      transaction_type 1
    end

    trait :with_paid_at do
      paid_at Time.now
    end

    trait :with_info do
      info 'Rincian tagihan dapat diakses di www.bpjs-kesehatan.go.id'
    end

    buyer_id 1
    customer_name "NISA KARTIKA INDIARTI"
    customer_number "0000001430071801"
    family_member_count 1
    branch_name "SEMARANG"
    amount 51000
    admin_charge 1500
    payment_period "01"
    paid_until "2017-09"
    partner "sepulsa"
    invoice_id 1
    remote_transaction_id 1
    transaction_type 0
    bpjs_kesehatan_family_members { build_list :bpjs_kesehatan_family_member, family_member_count }
  end
end
