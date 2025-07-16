FactoryBot.define do
  factory :sepulsa_response, class:Hash do

    trait :pdam_inquiry do
      stan  { '000135739333' }
      amount  { '184000' }
      transmission_datetime { '1020062418' }
      merchant_code { '6012' }
      rc  { '00' }
      admin_charge  { '0' }
      mti { '0210' }
      pan { '074003' }
      processing_code { '380000' }
      local_trx_date  { '20171020' }
      local_trx_time  { '062418' }
      settlement_date { '20171021' }
      acquiring_institution_id  { '008' }
      retrieval_ref_no  { '000135739333' }
      idpel { '1998800007' }
      blth  { '201708201709' }
      name  { 'Putin' }
      bill_count  { '2' }
      bill_repeat_count { '2' }
      rp_tag  { '184000' }
      status { true }
      response_code { '00' }
      bills {[
        {
          'bill_amount': ['100000'],
          'bill_date': ['201708'],
          'kubikasi': ['527-541'],
          'penalty': ['10000']
        },
        {
          'bill_amount': ['74000'],
          'bill_date': ['201709'],
          'kubikasi': ['527-541'],
          'penalty': ['0']
        }
      ]}
    end

    initialize_with { attributes.with_indifferent_access }
  end
end
