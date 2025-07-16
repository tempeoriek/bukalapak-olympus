module Response
  extend ActiveSupport::Concern
  include Postpaid::Constant
  include CreditCardBillHelper
  include BpjsKetenagakerjaanHelper

  def render_response(response, status)
    render json: { data: response, meta: { http_status: status } }, status: status
  end

  def render_response_with_paginantion(response, status, meta)
    render json: { data: response, meta: meta }, status: status
  end

  def render_error(error)
    render json: { errors: [error_response(error)], meta: { http_status: error.http_code } }, status: error.http_code
  end

  def render_inquiry_error(error)
    render json: { errors: [inquiry_error_response(error)], meta: { http_status: error.http_code } }, status: error.http_code
  end

  def partner_hash(partner)
    {
      name: PARTNER_OFFICIAL_NAME[partner]
    }
  end

  def electricity_inquiry_format(result)
    bills = result.bills.map do |bill|
      {
        bill_period: bill[:bill_period],
        penalty_fee: bill[:penalty_fee],
        amount: bill[:amount]
      }
    end

    {
      customer_number: result.customer_number,
      customer_name: result.customer_name,
      segmentation: result.segmentation,
      power: result.power,
      outstanding_bill: result.outstanding_bill,
      unpaid_bill: result.unpaid_bill,
      period: result.period,
      penalty_fee: result.penalty_fee,
      admin_charge: result.admin_charge,
      amount: result.amount,
      reference_number: result.reference_number,
      stand_meter: result.stand_meter,
      bills: bills,
      partner: partner_hash(result.partner),
      remaining_billing_sheet: result.remaining_billing_sheet
    }
  end

  def bpjs_kesehatan_inquiry_format(result)
    {
      amount: result.amount,
      admin_charge: result.admin_charge,
      customer_number: result.customer_number,
      customer_name: result.customer_name,
      branch_name: result.branch_name,
      family_member_count: result.family_member_count,
      family_members: result.family_members || [],
      payment_period: result.payment_period,
      paid_until: result.paid_until,
      partner: partner_hash(result.partner)
    }
  end

  def pdam_inquiry_format(result)
    response_body = {
      customer_number: result.customer_number,
      customer_name: result.customer_name,
      penalty_fee: result.penalty_fee,
      amount: result.amount,
      address: result.address,
      usage: result.usage,
      admin_charge: result.admin_charge,
      start_bill_period: result.start_bill_period,
      end_bill_period: result.end_bill_period,
      operator: result.operator,
      bills: result.bills.map { |bill| bill.except!(:tariff) },
      start_usage_meter: result.start_usage_meter,
      end_usage_meter: result.end_usage_meter,
      partner: partner_hash(result.partner),
      stand_meter: result.stand_meter,
      segel: result.segel,
      retribution: result.retribution,
      bills_period: result.bills_period
    }

    result.details&.map do |key, value|
      response_body[key] = value
    end

    response_body
  end

  def phone_credit_inquiry_format(result)
    {
      reference_no: result.reference_no,
      customer_number: result.customer_number,
      customer_name: CreditCardBillHelper.mask_name(result.customer_name),
      outstanding_bill: result.bill_count,
      admin_charge: 0,
      penalty_fee: 0,
      amount: result.total_amount,
      start_bill_period: result.bill_period.min,
      end_bill_period: result.bill_period.max,
      provider: {
        name: result.provider_name,
        product_name: result.provider_product_name,
        logo_url: result.provider_logo_url
      },
      partner: partner_hash(result.partner)
    }
  end

  def credit_card_bill_inquiry_format(result)
    response = {
      customer_number: result.customer_number,
      statement_date: result.statement_date,
      due_date: result.due_date,
      amount: result.amount,
      admin_charge: result.biller.admin_charge,
      minimum_payment: result.minimum_payment,
      partner: partner_hash(result.partner.name),
      biller: {
        id: result.biller.id,
        name: result.biller.name,
        image_url: result.biller.image_url
      }
    }

    response[:customer_name] = CreditCardBillHelper.mask_name(result.displayed_name) if result.displayed_name

    response
  end

  def credit_card_bill_pnl_inquiry_format(form)
    form = masking(form, form.biller.biller_code)
    response = {
      customer_number: form.customer_number,
      amount: form.amount,
      admin_charge: form.biller.admin_charge,
      minimum_payment: CreditCardBillTransaction::MINIMUM_BASE_AMOUNT,
      partner: partner_hash(form.partner.name),
      biller: {
        id: form.biller.id,
        name: form.biller.name,
        image_url: form.biller.image_url
      }
    }
  end

  def credit_card_bill_visa_inquiry_format(form)
    credit_card_bill_pnl_inquiry_format(form)
  end

  def bpjs_ketenagakerjaan_inquiry_format(result)
    masked_customer_name = if result.bpjs_tk_type == :bpu
                             BpjsKetenagakerjaanHelper.mask_name(result.customer_name)
                           else
                             result.customer_name
    end

    response = {
      customer_number: result.customer_number,
      customer_name: masked_customer_name,
      bpjs_tk_type: result.bpjs_tk_type,
      amount: result.amount,
      admin_charge: result.admin_charge,
      bills: result.bills,
      partner: partner_hash(result.partner),
      branch_name: result.branch_name,
      division: result.division,
      npp: result.npp,
      bill_code: result.bill_code,
      period: {
        total_month: !result.unpaid_bills ? result.payment_period : nil,
        start_date: result.start_bill_period,
        end_date: result.end_bill_period
      },
      unpaid_bills: result.unpaid_bills
    }
  end

  def recurrence_format(result)
    {
      transaction_id: result.id,
      amount: result.amount
    }
  end

  def error_response(error)
    {
      message: error.message,
      code: error.error_code
    }
  end

  def inquiry_error_response(error)
    message = case error
      when Exceptions::UnregisteredNumber
        default_message = 'Nomor tidak terdaftar. Coba periksa lagi, yuk.'
        error.message != default_message ? error.message : default_message
      when Exceptions::BillAlreadyPaid then error.message
      when Exceptions::Thor::PdamBillCanOnlyBePaidDirectly then error.message
      when Exceptions::Thor::CutOff then error.message
      when Exceptions::AccountSuspended then error.message
      else 'Terjadi kesalahan pada sistem. Silahkan coba lagi.'
    end

    {
      message: message,
      code: error.error_code
    }
  end
end
