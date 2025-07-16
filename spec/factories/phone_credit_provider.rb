FactoryBot.define do
  factory :phone_credit_provider, class: PhoneCreditProvider do
    provider 'Telkomsel'
    product_name 'Telkomsel Halo'
    active 1
    logo_url 'http://i0.kym-cdn.com/entries/icons/mobile/000/013/564/doge.jpg'
    partner_product_id 113
    partner 'sepulsa'
    partner_admin_charge 1000
    bukalapak_admin_charge 500

    trait :inactive do
      active 0
    end

    trait :deleted do
      active -1
    end
  end
end
