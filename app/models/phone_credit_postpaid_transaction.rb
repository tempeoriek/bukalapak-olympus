class PhoneCreditPostpaidTransaction < ApplicationRecord
  include TransactionStateMachine
  include Postpaid::Constant

  enum state: {
    pending: 0,
    processed: 1,
    succeeded: 2,
    failed: 3,
    paid: 4,
    partner_succeeded: 5,
    partner_failed: 6,
    expired: 7,
    cancelled: 8
  }

  enum partner: {
    sepulsa: 0
  }

  enum transaction_type: {
    normal: 0,
    agent: 1,
    procurement: 2,
  }

  validates :buyer_id, presence: true, numericality: { only_integer: true }
  validates :customer_name, presence: true
  validates :phone_number, presence: true
  validates :outstanding_bill, presence: true, numericality: { only_integer: true }
  validates :start_bill_period, presence: true
  validates :end_bill_period, presence: true
  validates :bill_amount, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :partner_admin_charge, presence: true, numericality: { only_integer: true }
  validates :bukalapak_admin_charge, presence: true, numericality: { only_integer: true }
  validates :total_amount, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :provider_id, presence: true
  validates :invoice_id, allow_blank: true, numericality: { only_integer: true }

  def order_id
    "#{PHONE_CREDIT_POSTPAID_PREFIX}-#{remote_transaction_id}"
  end

  # alias
  def customer_number
    phone_number
  end

  def product_type
    PHONE_CREDIT_PRODUCT
  end

  def partner_name
    partner
  end

  def partner_hash
    {
      name: PARTNER_OFFICIAL_NAME[partner]
    }
  end

  def recurrent?
    !template_detail_id.nil?
  end

  def as_json(_options={})
    result = {}
    result['id'] = id
    result['buyer_id'] = buyer_id
    result['type'] = Channel::Config::TRANSACTION_TYPE[PHONE_CREDIT_PRODUCT]
    result['invoice_id'] = invoice_id
    result['remote_transaction_id'] = remote_transaction_id
    result['reference_no'] = reference_number
    result['customer_name'] = customer_name
    result['customer_number'] = customer_number
    result['outstanding_bill'] = outstanding_bill
    # Set admin to 0 when returned to client
    # Because of our agreement with our partner
    # we couldn't show admin_fee to user detail transaction
    result['admin_charge'] = 0
    result['penalty_fee'] = 0
    result['amount'] = total_amount
    result['start_bill_period'] = start_bill_period
    result['end_bill_period'] = end_bill_period
    result['state'] = state
    result['partner'] = partner_hash
    result['provider'] = {
      'name': provider.provider,
      'product_name': provider.product_name,
      'logo_url': provider.logo_url
    }
    result['state_changed_at'] = {
      'processed_at': processed_at,
      'succeeded_at': succeeded_at,
      'failed_at': failed_at
    }
    result['transaction_type'] = transaction_type
    result
  end

  def provider
    @provider ||= PhoneCreditProvider.find provider_id
  end

  def admin_charge
    partner_admin_charge + bukalapak_admin_charge
  end

  def amount
    total_amount
  end

  def bill_period
    first_bill_period = I18n.l(Date.parse(start_bill_period.to_s), format: "%B %Y")
    last_bill_period = I18n.l(Date.parse(end_bill_period.to_s), format: "%B %Y")
    first_bill_period == last_bill_period ? first_bill_period : first_bill_period + " - " + last_bill_period
  end

  def is_mitra?
    transaction_type == AGENT_BUYER_TYPE || transaction_type == COLLECTING_AGENT_BUYER_TYPE
  end

  def biller_product
    provider&.provider
  end
end
