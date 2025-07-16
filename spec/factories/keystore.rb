FactoryBot.define do
  factory :keystore, class: Keystore do
    key 'bni_access_token'

    trait :with_expired_ttl do
      value 'example value'
      expiration_time { Time.now - 5.minute }
    end

    trait :with_ttl do
      value 'example value'
      expiration_time { Time.now + 5.minute }
    end
  end
end
