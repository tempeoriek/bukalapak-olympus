FactoryBot.define do
  factory :fortuna_thor_response, class:Hash do

    trait :pdam_inquiry do
      customer_number { '19989000000' }
      customer_name { 'JUNAIDI XX001' }
      start_bill_period { '2012-01-01' }
      end_bill_period { '2012-01-01' }
      bukalapak_admin_charge { 600 }
      partner_admin_charge {900}
      bills {[
            { 
              'bill_period': '2012-01-01',
              'amount': 100000,
              'penalty_fee': 0,
              'cubication': '402-458',
              'usage': '56 M3' 
            }
      ]}
      details {
        {
          'sub_segment': 'Group rate: GOL 3A, Description: Rumah Tangga', 
          'biller_ref': nil
        }
      }
      start_usage_meter { 402 }
      end_usage_meter { 458 }
      stand_meter { '402-408' }
      segel {3000}
      retribution { 1000}
      penalty_fee {0}
      usage {'56 M3'}
      amount {105000}
      partner { 'fortuna_thor' }
      operator {
        {
          'id': 1001,
          'name': 'PDAM Jakarta',
          'group': 'DKI Jakarta',
          'image_url': 'http://i0.kym-cdn.com/entries/icons/mobile/000/013/564/doge.jpg',
          'terms_and_conditions': 'term and condition'
        }
      }
    end

    initialize_with { attributes.with_indifferent_access }
  end
end
