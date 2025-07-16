FactoryBot.define do
  factory :pdam_operator, class: PdamOperator do
    code "pdam_denpasar"
    name "Denpasar"
    group "Bali"
    active 1
    partner 0
    image_url "http://i0.kym-cdn.com/entries/icons/mobile/000/013/564/doge.jpg"
    bukalapak_admin_charge Test::BUKALAPAK_ADMIN_CHARGE
    partner_admin_charge Test::PARTNER_ADMIN_CHARGE
    bill_day 20
    due_day 1
    terms_and_conditions "term and conditions"
    revenue 1000
    have_issue 0
    update_selling_price false

    trait :sepulsa do
      partner 0
    end

    trait :dji do
      partner 1
    end

    trait :vsi_thor do
      partner 3
    end

    trait :mkm_thor do
      partner 4
    end

    trait :fortuna_thor do
      partner 5
    end

    trait :selected_area_code do
      code "400241"
      name "PDAM Kab. Kendal"
      group "Jawa Tengah"
    end

    trait :pdam_surabaya do
      name "PDAM Surabaya"
    end

    trait :pdam_jakarta do
      name "PDAM Jakarta"
    end

    trait :inactive do
      active 0
    end
  end
end
