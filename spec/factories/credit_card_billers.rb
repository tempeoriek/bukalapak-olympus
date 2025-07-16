FactoryBot.define do
  factory :credit_card_biller, class: CreditCardBiller do
    image_url 'https://s2.bukalapak.com/images/desktop/aset-brand/section1-3.png'
    active 'active'
    non_bni
    partner_pnl

    trait :bni do
      name 'BNI'
      transient do
        biller_code { "BNI" }
      end
    end

    trait :anz do
      name 'DBS/ANZ'
      transient do
        biller_code { "ANZ" }
      end
    end

    trait :amex do
      name 'AMEX'
      transient do
        biller_code { "AMEX" }
      end
    end

    trait :non_bni do
      name 'BRI'

      transient do
        biller_code { "BRI" }
      end
    end

    trait :visa do
      name 'Bank ICBC'

      transient do
        biller_code { "DEFAULT" }
      end
    end

    trait :cimbniaga_thor do
      name 'CIMB'

      transient do
        biller_code { "DEFAULT" }
      end
    end

    trait :partner_pnl do
      transient do
        partners { %W[pnl] }
      end
    end

    trait :partner_bni do
      transient do
        partners { %W[bni] }
      end
    end

    trait :partner_visa do
      transient do
        partners { %W[visa] }
      end
    end

    trait :thor do
      transient do
        partners { %W[thor] }
      end
    end

    trait :partner_cimbniaga_thor do
      transient do
        partners { %W[cimbniaga_thor] }
      end
    end

    after(:create) do |credit_card_biller, eval|
      eval.partners.each do |partner|
        create(:credit_card_bill_partner, partner.to_sym, credit_card_biller: credit_card_biller, biller_code: eval.biller_code)
      end if eval.respond_to?(:partners) && eval.respond_to?(:biller_code)
    end
  end
end
