class PdamTransaction < ApplicationRecord
  include TransactionStateMachine
  include Postpaid::Constant
  include CachePartnerResponseUtility
  include MiddlemanResponseMapperUtility

  has_many :pdam_bills
  belongs_to :pdam_operator

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
    sepulsa: 0,
    dji: 1,
    'dji-pdam-to': 2,
    vsi_thor: 3,
    mkm_thor: 4,
    fortuna_thor: 5,
    bms_thor: 6
  }

  enum transaction_type: {
    normal: 0,
    agent: 1,
    procurement: 2,
    collecting_agent: 4
  }

  validates :buyer_id, presence: true, numericality: { only_integer: true }
  validates :customer_name, presence: true
  validates :customer_number, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :penalty_fee, presence: true, numericality: { only_integer: true }
  validates :bukalapak_admin_charge, presence: true, numericality: { only_integer: true }
  validates :partner_admin_charge, presence: true, numericality: { only_integer: true }
  validates :invoice_id, allow_blank: true, numericality: { only_integer: true }
  validates :partner, presence: true
  validates :pdam_operator_id, presence: true
  validates :pdam_bills, presence: true

  validate :valid_admin_charge

  def order_id
    "#{PDAM_PREFIX}-#{remote_transaction_id}"
  end

  def product_type
    PDAM_PRODUCT
  end

  # alias
  def operator
    pdam_operator
  end

  def period
    date = pdam_bills.pluck(:bill_period)
    date.sort!
    [date.first, date.last]
  end

  # need review on whitelist
  def usage
    usages = pdam_bills.pluck(:usage)
    return nil if nil.in? usages

    total = usages.map{ |usage| usage }.inject(0, :+)
    total
  end

  def tariff_type
    tariff = pdam_bills.first.tariff || ""
    tariff.strip
  end

  def total_penalty_fee
    total_penalty_fee = 0
    pdam_bills.each do |bill|
      total_penalty_fee += bill.penalty_fee
    end
    total_penalty_fee
  end

  def admin_charge
    bukalapak_admin_charge + partner_admin_charge
  end

  def state_changed_at
    {
      processed_at: processed_at,
      succeeded_at: succeeded_at,
      failed_at: failed_at
    }
  end

  def partner_name
    partner
  end

  def partner_hash
    {
      name: PARTNER_OFFICIAL_NAME[partner]
    }
  end

  def start_end_usage_meter
    cubications = pdam_bills.pluck(:cubication)
    start_meter = cubications.map { |cubication| cubication&.split('-').first.to_i }.min
    end_meter = cubications.map { |cubication| cubication&.split('-').last.to_i }.max

    {
      start_usage_meter: start_meter,
      end_usage_meter: end_meter
    }
  end

  def bill_period
    first_bill_period = I18n.l(Date.parse(pdam_bills.first.bill_period.to_s), format: "%B %Y")
    last_bill_period = I18n.l(Date.parse(pdam_bills.last.bill_period.to_s), format: "%B %Y")
    first_bill_period == last_bill_period ? first_bill_period : first_bill_period + " - " + last_bill_period
  end

  def recurrent?
    !template_detail_id.nil?
  end

  def valid_admin_charge
    errors.add(:base, 'Admin charge tidak sesuai dengan jumlah tagihan') unless valid_bukalapak_admin_charge? && valid_partner_admin_charge?
  end

  def valid_bukalapak_admin_charge?
    operator.bukalapak_admin_charge * pdam_bills.length == bukalapak_admin_charge
  end

  def valid_partner_admin_charge?
    operator.partner_admin_charge * pdam_bills.length == partner_admin_charge
  end

  def as_json(_options={})
    result = super(
      only: [
        :id,
        :buyer_id,
        :invoice_id,
        :remote_transaction_id,
        :customer_number,
        :customer_name,
        :amount,
        :penalty_fee,
        :start_bill_period,
        :end_bill_period,
        :state,
        :address,
        :stand_meter,
        :segel,
        :retribution,
        :reference_number,
      ],
      include: [
        {
          pdam_operator: {
            only: [
              :id,
              :name,
              :group,
              :image_url,
              :terms_and_conditions,
              :have_issue,
              :update_selling_price
            ]
          }
        }
      ]
    )
    result.merge!(start_end_usage_meter)
    result['usage'] = usage
    result['state_changed_at'] = state_changed_at
    result['admin_charge'] = admin_charge
    result['bills'] = pdam_bills.as_json
    result['operator'] = result.delete 'pdam_operator'
    result['partner'] = partner_hash
    result['type'] = Channel::Config::TRANSACTION_TYPE[PDAM_PRODUCT]
    result['transaction_type'] = transaction_type
    if self.collecting_agent?
      result['response_code'] = response_code
      result['failed_reason'] = failed_reason
    end
    result['bills_period'] = bills_period

    # retrieve all details on pdam transactions
    details&.map do |key, value|
      result[key] = value
    end

    result
  end

  def is_mitra?
    transaction_type == AGENT_BUYER_TYPE || transaction_type == COLLECTING_AGENT_BUYER_TYPE
  end

  def response_code
    retrieve_middleman_response_code(product_type, partner_name, partner_response_code)
  end

  def failed_reason
    retrieve_middleman_failed_reason(partner_name, partner_response_code)
  end

  def middleman_state
    case state.to_sym
    when :failed, :expired, :partner_failed, :cancelled
      :failed
    when :succeeded, :partner_succeeded
      :succeeded
    else # :pending, :paid, :processed
      :pending
    end
  end

  def middleman_details
    {
      customer_number:      self.customer_number,
      customer_name:        self.customer_name,
      amount:               self.amount,
      admin_charge:         self.admin_charge,
      start_bill_period:    self.start_bill_period,
      end_bill_period:      self.end_bill_period,
      usage:                self.usage,
      address:              self.address,
      end_usage_meter:      self.start_end_usage_meter[:end_usage_meter],
      start_usage_meter:    self.start_end_usage_meter[:start_usage_meter],
      operator:             self.operator,
      bills:                self.pdam_bills.as_json,
    }
  end

  def bills_period
    same_month = start_bill_period.month == end_bill_period.month
    same_year = start_bill_period.year == end_bill_period.year

    return "#{I18n.l(start_bill_period, format: :short_month)} - #{I18n.l(end_bill_period, format: :short_month)}" unless same_month && same_year

    "#{start_bill_period.day} - #{end_bill_period.day} #{I18n.l(start_bill_period, format: '%b %Y')}"
  end

  def biller_product
    operator&.code
  end

  private

  def partner_response_code
    action = "create"
    retrieve_partner_response(product_type, action, partner_name, remote_transaction_id)
  end
end
