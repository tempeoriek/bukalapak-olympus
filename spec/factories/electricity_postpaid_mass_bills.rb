FactoryBot.define do
  factory :electricity_postpaid_mass_bill do
    mass_bill_id { SecureRandom.uuid }

    trait :with_transaction do
      association :postpaid_transaction, factory: :postpaid_transaction_with_bill
    end

  end
end
