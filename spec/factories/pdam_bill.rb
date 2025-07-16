FactoryBot.define do
  factory :pdam_bill, class: PdamBill do
    #Code rspec masih terbatas 2 unit bill (karena limitasi sequence yang bertambah nilainya setiap dipanggil)
    sequence(:bill_period) { |n| Date.current.beginning_of_month - ((n - 1) % 2).month }
    penalty_fee 0
    amount 11100
    # cubication '00000001-00000002'
    sequence(:cubication) { |n| ((n - 1) % 2 * 2 + 1).to_s.rjust(8, '0') + '-' + ((n - 1) % 2 * 2 + 2).to_s.rjust(8, '0') }
    tariff nil
    usage 1


    trait :error_cubication do
      cubication '00000001#00000002'
    end
  end
end
