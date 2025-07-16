FactoryBot.define do
  factory :postpaid_transaction_with_bill, class: PostpaidTransaction do
    transient do
      bills_count 1
    end

    trait :pending do
      state 0
    end

    trait :processed do
      state 1
    end

    trait :succeeded do
      paid_at DateTime.now
      state 2
    end

    trait :failed do
      state 3
    end

    trait :paid do
      state 4
    end

    trait :partner_succeeded do
      paid_at DateTime.now
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

    trait :partner_sepulsa do
      partner 'sepulsa'
    end

    trait :partner_ayoconnect do
      partner 'ayoconnect'
    end

    trait :partner_bukopin do
      partner 'bukopin'
    end

    trait :partner_tektaya do
      partner 'tektaya'
    end

    trait :partner_tektaya_bukaconnect do
      partner 'tektaya_bukaconnect'
    end

    trait :vsi_thor do
      partner 'vsi_thor'
    end

    trait :recurrent do
      template_detail_id 1
    end

    trait :agent do
      transaction_type 1
    end

    trait :collecting_agent do
      transaction_type 4
    end

    trait :without_partner_transction_id do
      partner_transaction_id nil
    end

    buyer_id 1
    customer_name 'ABDUL GHALIB'
    customer_number 512_345_610_000
    power 900
    segmentation 'R1'
    stand_meter '27135 - 27280'
    outstanding_bill { bills_count }
    admin_charge { bills_count * 1500 }
    bukalapak_commission 3000
    amount { bills_count * 88_500 }
    penalty_fee { bills_count * 1_000 }
    partner_transaction_id '2345'
    remote_transaction_id 1
    reference_number 'refnumber13123123'
    invoice_id 1
    transaction_type 0
    partner 0
    bills { build_list :bill, bills_count }

    trait :with_mass_bill do
      electricity_postpaid_mass_bill
    end
  end
end
