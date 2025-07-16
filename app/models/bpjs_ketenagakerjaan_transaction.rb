class BpjsKetenagakerjaanTransaction < ApplicationRecord
  include TransactionStateMachine
  include Postpaid::Constant
  include BpjsKetenagakerjaanHelper

  has_many :bpjs_ketenagakerjaan_bills

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
    ayoconnect: 0
  }

  enum bpjs_tk_type: {
    bpu: 0,
    pu: 1
  }

  enum transaction_type: {
    normal: 0,
    agent: 1,
    procurement: 2
  }

  validates :buyer_id, presence: true, numericality: { only_integer: true }
  validates :customer_number, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :admin_charge, presence: true, numericality: { only_integer: true }
  validates :start_bill_period, presence: true
  validates :end_bill_period, presence: true

  def product_type
    BPJS_KETENAGAKERJAAN_PRODUCT
  end

  def order_id
    "#{BPJS_KETENAGAKERJAAN_PREFIX}-#{remote_transaction_id}"
  end

  def image_url
    'https://s4.bukalapak.com/images/virtual_product/logo_bpjs_tk.jpg'
  end

  def partner_name
    partner
  end

  def partner_hash
    {
      name: PARTNER_OFFICIAL_NAME[partner]
    }
  end

  def partner_object
    BpjsKetenagakerjaanPartner.find_by(name: partner)
  end

  def is_mitra?
    transaction_type == AGENT_BUYER_TYPE || transaction_type == COLLECTING_AGENT_BUYER_TYPE
  end

  def recurrent?
    !template_detail_id.nil?
  end

  def period
    {
      total_month: payment_period.present? && !unpaid_bills? ? payment_period.to_i : nil,
      start_date: start_bill_period,
      end_date: end_bill_period
    }
  end

  def bills
    bpjs_ketenagakerjaan_bills&.map do |bill|
      {
        jht: bill.jht,
        jkk: bill.jkk,
        jkm: bill.jkm,
        jkp: bill.jkp,
        jp: bill.jp,
        amount: bill.amount
      }.compact
    end
  end

  def as_json(_options = {})
    result = super(
      only: %i[
        id
        buyer_id
        remote_transaction_id
        invoice_id
        reference_number
        state
        processed_at
        succeeded_at
        failed_at
        bpjs_tk_type
        amount
        admin_charge
        customer_number
        customer_name
        branch_name
        bill_code
        npp
        division
        unpaid_bills
      ],
      methods: [:bills]
    )

    result['type'] = Channel::Config::TRANSACTION_TYPE[BPJS_KETENAGAKERJAAN_PRODUCT]
    result['image_url'] = image_url
    result['transaction_type'] = transaction_type
    result['partner'] = partner_hash
    result['period'] = period

    masked = _options.dig(:masked).present? ? _options.dig(:masked) : false
    result['customer_name'] = BpjsKetenagakerjaanHelper.mask_name(customer_name) if masked && bpu?

    result
  end

  def biller_product
    nil # currently no biller product for bpjs ketenagakerjaan
  end
end
