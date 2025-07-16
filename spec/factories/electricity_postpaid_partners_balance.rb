FactoryBot.define do
  factory :electricity_postpaid_partners_balance, class: ElectricityPostpaidPartnersBalance do
    trait :bukalapak do
      amount 10000000
      threshold 1000000
      type 1
    end

    trait :mitra do
      amount 20000000
      threshold 2000000
      type 2
    end

    trait :bukaconnect do
      amount 30000000
      threshold 3000000
      type 3
    end
  end
end
