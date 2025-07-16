include Postpaid::Constant

FactoryBot.define do
  factory :cc_transaction, class: CreditCardBillTransaction do
    id 2
    buyer_id 1
    invoice_id 1
    remote_transaction_id 1
    customer_name 'Sumartono Hiu'
    customer_number '4665-73XX-XXXX-0117'
    statement_date Date.new(2012, 10, 11)
    due_date Date.new(2012, 10, 12)
    minimum_payment 2000000
    # credit_card_biller_id 1
    # credit_card_bill_partner_id 1
    token 'dfa94baf4f826e336ccd9a1dd9ffe3fd'
    card_data 'ba1854b695a6a154e8f9f8211358bf94'
    amount 2000000
    bukalapak_admin_charge 0
    partner_admin_charge 0
    transaction_type 0
    response_code 0
    credit_card_biller { create(:credit_card_biller, :bni, :partner_bni) }
    credit_card_bill_partner { credit_card_biller.partner }

    trait :visa do
      customer_number 'XXXX-XXXX-XXXX-1111'
      credit_card_biller { create(:credit_card_biller, :visa, :partner_visa) }
    end

    trait :partner_pnl do
      credit_card_biller { create(:credit_card_biller, :bni, :partner_pnl) }
    end

    trait :pending do
      state 0
      created_at '2018-12-18 09:39:13'
    end

    trait :pending_visa do
      state 0
      customer_number 'XXXX-XXXX-XXXX-1111'
      token '7010000000112271111'
      card_data nil
      created_at '2020-06-15 21:50:32'
    end

    trait :paid do
      state 4
      created_at '2018-12-18 16:39:13'
      paid_at '2018-12-18 17:39:12'
    end

    trait :paid_thor do
      customer_number '4665-4665-4665-1111'
      credit_card_biller { create(:credit_card_biller, :cimbniaga_thor, :partner_cimbniaga_thor) }
      state 4
      created_at '2018-12-18 16:39:13'
      paid_at '2018-12-18 17:39:12'
    end

    trait :paid_visa do
      state 4
      customer_number 'XXXX-XXXX-XXXX-1111'
      token '7010000000112271111'
      card_data nil
      created_at '2020-06-15 21:50:32'
      paid_at '2020-06-15 21:51:32'
    end

    trait :processed do
      state 1
      reference_number 'G001T00100000001'
      created_at '2018-12-18 16:39:13'
      paid_at '2018-12-18 17:39:12'
      processed_at '2018-12-18 17:39:13'
    end

    trait :processed_visa do
      state 1
      reference_number 'G001T00100000001'
      created_at '2020-06-15 21:50:32'
      paid_at '2020-06-15 21:51:32'
      processed_at '2020-06-15 21:52:32'
      customer_number 'XXXX-XXXX-XXXX-1111'
      token '7010000000112271111'
      card_data nil
    end

    trait :succeeded do
      state 2
      reference_number 'G001T00100000001'
      partner_journal_number "123456789"
      partner_financial_journal_number "123456"
      created_at '2018-12-18 16:39:13'
      paid_at '2018-12-18 17:39:12'
      processed_at '2018-12-18 17:39:13'
      succeeded_at '2018-12-18 17:40:13'
    end

    trait :failed do
      state 3
      reference_number 'G001T00100000001'
      partner_journal_number "123456789"
      partner_financial_journal_number "123456"
      created_at '2018-12-18 16:39:13'
      paid_at '2018-12-18 17:39:12'
      processed_at '2018-12-18 17:39:13'
      failed_at '2018-12-18 17:40:13'
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

    trait :bill_insufficient do
      amount 4000
    end

    trait :low_min_payment do
      minimum_payment 3000
    end

    trait :agent do
      transaction_type 1
    end

    trait :collecting_agent do
      transaction_type 4
    end

  end
end
