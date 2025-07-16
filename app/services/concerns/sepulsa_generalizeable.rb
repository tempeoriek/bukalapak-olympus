module SepulsaGeneralizeable
  include PdamUtility
  include Postpaid::Constant

  def sepulsa_response_generalizer(response, product_name)
    case product_name
    when BPJS_KESEHATAN_PRODUCT
      build_bpjs_kesehatan_response_generalizer(response)
    when ELECTRICITY_PRODUCT
      build_electricity_postpaid_response_generalizer(response)
    when PDAM_PRODUCT
      build_pdam_response_generalizer(response)
    when PHONE_CREDIT_PRODUCT
      build_phone_credit_postpaid_response_generalizer(response)
    else
      raise 'Unsupported type'
    end
  end

  def build_bpjs_kesehatan_response_generalizer(response)
    response_generalizer = ResponseGeneralizer::BpjsKesehatan.new
    response_generalizer.partner_transaction_id = response[:transaction_id]
    response_generalizer.status = PARTNER_STATUS[SEPULSA][response[:status]]
    response_generalizer.reference_number = response[:sw_reff]
    response_generalizer.info = response[:info_text]

    response_generalizer
  end

  def build_electricity_postpaid_response_generalizer(response)
    # refactor responsegerenalizer
    response_generalizer = ResponseGeneralizer::ElectricityPostpaid.new(response, ElectricityPostpaidPartner.find_by_name('sepulsa'))
    response_generalizer.partner_transaction_id = response[:transaction_id]
    response_generalizer.status = PARTNER_STATUS[SEPULSA][response[:status]]
    response_generalizer.info_text = response[:info_text]
    response_generalizer.reference_number= response[:reference_number]

    response_generalizer
  end

  def build_pdam_response_generalizer(response)
    bills = response[:bills].map do |bill|
      {
        # convert YYYYMM format to YYYY-MM
        bill_period: ::Converter::StringToDate.convert(bill[:bill_date][0], string_format: YYYYMM),
        amount: bill[:bill_amount][0].to_i,
        penalty_fee: bill[:penalty][0].to_i,
        cubication: bill[:kubikasi][0],
        usage: bill_usage(bill[:kubikasi][0])
      }
    end
    response_generalizer = ResponseGeneralizer::Pdam.new
    response_generalizer.bills = bills
    response_generalizer.partner_transaction_id = response[:transaction_id]
    response_generalizer.status = PARTNER_STATUS[SEPULSA][response[:status]]

    response_generalizer
  end

  def build_phone_credit_postpaid_response_generalizer(response)
    response_generalizer = ResponseGeneralizer::PhoneCreditPostpaid.new
    response_generalizer.partner_transaction_id = response[:transaction_id]
    response_generalizer.status = PARTNER_STATUS[SEPULSA][response[:status]]

    response_generalizer
  end
end
