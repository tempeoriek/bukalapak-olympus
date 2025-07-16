FactoryBot.define do
  factory :electricity_postpaid_partner, class: ElectricityPostpaidPartner do
    trait :sepulsa do
      name 'sepulsa'
      partner_admin_charge 1000
      bukalapak_admin_charge 500
      bukalapak_commission 950
      partner_type 'normal'
      electricity_postpaid_partners_balances do
        [
          create(:electricity_postpaid_partners_balance, :bukalapak),
          create(:electricity_postpaid_partners_balance, :mitra),
          create(:electricity_postpaid_partners_balance, :bukaconnect)
        ]
      end
    end

    trait :bukopin do
      name 'bukopin'
      partner_admin_charge 2750
      bukalapak_admin_charge 0
      partner_type 'normal'
    end

    trait :ayoconnect do
      name 'ayoconnect'
      partner_admin_charge 1000
      bukalapak_admin_charge 1000
      partner_type 'normal'
    end

    trait :tektaya do
      name 'tektaya'
      partner_admin_charge 50
      bukalapak_admin_charge 2450
      partner_type 'normal'
      electricity_postpaid_partners_balances do
        [
          create(:electricity_postpaid_partners_balance, :bukalapak),
          create(:electricity_postpaid_partners_balance, :mitra),
          create(:electricity_postpaid_partners_balance, :bukaconnect)
        ]
      end
    end

    trait :sepulsa_bukaconnect do
      name 'sepulsa_bukaconnect'
      partner_admin_charge 1000
      bukalapak_admin_charge 500
      bukalapak_commission 950
      partner_type 'collecting-agent'
    end

    trait :bukopin_bukaconnect do
      name 'bukopin_bukaconnect'
      partner_admin_charge 2750
      bukalapak_admin_charge 0
      bukalapak_commission 950
      partner_type 'collecting-agent'
    end

    trait :ayoconnect_bukaconnect do
      name 'ayoconnect_bukaconnect'
      partner_admin_charge 1000
      bukalapak_admin_charge 1000
      bukalapak_commission 950
      partner_type 'collecting-agent'
    end

    trait :tektaya_bukaconnect do
      name 'tektaya_bukaconnect'
      partner_admin_charge 50
      bukalapak_admin_charge 2450
      bukalapak_commission 950
      partner_type 'collecting-agent'
    end

    trait :vsi_thor do
      name 'vsi_thor'
      partner_admin_charge 1000
      bukalapak_admin_charge 1000
      partner_type 'normal'
      code 'VSICODE'
    end

    trait :sat_thor do
      name 'sat_thor'
      partner_admin_charge 1000
      bukalapak_admin_charge 1000
      partner_type 'normal'
      code 'SATCODE'
    end

    trait :active do
      state 1
    end

    trait :inactive do
      state 0
    end

    electricity_postpaid_partners_balances []
  end
end
