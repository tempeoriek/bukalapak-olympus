class PostpaidTransaction < ApplicationRecord
  include TransactionStateMachine
  include Postpaid::Constant
  include CachePartnerResponseUtility
  include MiddlemanResponseMapperUtility

  has_many :bills
  has_one :electricity_postpaid_mass_bill

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
    bukopin: 1,
    ayoconnect: 2,
    tektaya: 3,
    sepulsa_bukaconnect: 4,
    bukopin_bukaconnect: 5,
    ayoconnect_bukaconnect: 6,
    tektaya_bukaconnect: 7,
    vsi_thor: 8,
    sat_thor: 9
  }

  enum transaction_type: {
    normal: 0,
    agent: 1,
    procurement: 2,
    collecting_agent: 4,
  }

  validates :buyer_id, presence: true, numericality: { only_integer: true }
  validates :customer_name, presence: true
  validates :customer_number, presence: true, format: { with: /\A[0-9]+\Z/, message: I18n.t('electricity.errors.wrong_customer_number_format') }
  validates :power, presence: true, numericality: { only_integer: true }
  validates :outstanding_bill, presence: true, numericality: { only_integer: true }
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :penalty_fee, presence: true, numericality: { only_integer: true }
  validates :admin_charge, presence: true, numericality: { only_integer: true }
  validates :bukalapak_commission, presence: true, numericality: { :greater_than_or_equal_to => 0, only_integer: true }
  validates :invoice_id, allow_blank: true, numericality: { only_integer: true }
  validates :partner, presence: true
  validates :bills, presence: true

  def buyer_type
    case transaction_type
    when 'normal'
      NORMAL_BUYER_TYPE
    when 'agent'
      AGENT_BUYER_TYPE
    when 'procurement'
      BUKA_PENGADAAN_BUYER_TYPE
    end
  end

  def period
    bills.pluck(:bill_period)
  end

  def order_id
    "#{ELECTRICITY_POSTPAID_PREFIX}-#{remote_transaction_id}"
  end

  def product_type
    ELECTRICITY_PRODUCT
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
    ElectricityPostpaidPartner.find_by(name: partner)
  end

  def bill_period
    first_bill_period = I18n.l(Date.parse(bills.first.bill_period.to_s), format: "%B %Y")
    last_bill_period = I18n.l(Date.parse(bills.last.bill_period.to_s), format: "%B %Y")
    first_bill_period == last_bill_period ? first_bill_period : first_bill_period + " - " + last_bill_period
  end

  def image_url
    'https://s4.bukalapak.com/images/virtual_product/logo_pln.png'
  end

  def recurrent?
    !template_detail_id.nil?
  end

  def as_json(_options={})
    result = super(
      only: [
        :id,
        :buyer_id,
        :invoice_id,
        :remote_transaction_id,
        :reference_number,
        :customer_number,
        :customer_name,
        :stand_meter,
        :segmentation,
        :power,
        :outstanding_bill,
        :unpaid_bill,
        :penalty_fee,
        :admin_charge,
        :amount,
        :state,
        :info_text,
        :processed_at,
        :succeeded_at,
        :failed_at
      ],
      methods: [
        :period,
        :mass_bill_id
      ],
      include: {
        bills: {
          only: [
            :bill_period,
            :penalty_fee,
            :amount
          ]
        }
      }
    )
    result['partner_name'] = partner
    result['partner'] = partner_hash
    result['type'] = Channel::Config::TRANSACTION_TYPE[ELECTRICITY_PRODUCT]
    result['image_url'] = image_url
    result['transaction_type'] = transaction_type
    result
  end

  def state_changed_at
    {
      processed_at: self.processed_at,
      succeeded_at: self.succeeded_at,
      failed_at: self.failed_at
    }
  end

  def mitra_transaction_type?
    transaction_type == AGENT_BUYER_TYPE
  end

  def bukaconnect_transaction_type?
    transaction_type == COLLECTING_AGENT_BUYER_TYPE
  end

  def is_mitra?
    mitra_transaction_type? || (bukaconnect_transaction_type? && !partner_object.bukaconnect_partner?)
  end

  def is_bukaconnect?
    bukaconnect_transaction_type? && partner_object.bukaconnect_partner?
  end

  def state_changed_at
    {
      processed_at: self.processed_at,
      succeeded_at: self.succeeded_at,
      failed_at: self.failed_at
    }
  end

  def response_code
    retrieve_middleman_response_code(product_type, partner_name, partner_response_code)
  end

  def failed_reason
    retrieve_middleman_failed_reason(partner_name, partner_response_code)
  end

  def middleman_state
    case state.to_sym
    when :failed, :expired, :partner_failed, :canceled
      :failed
    when :succeeded, :partner_succeeded
      :succeeded
    else # :pending, :paid, :processed
      :pending
    end
  end

  def middleman_details
    {
      reference_number:     self.reference_number,
      customer_number:      self.customer_number,
      customer_name:        self.customer_name,
      segmentation:         self.segmentation,
      power:                self.power,
      stand_meter:          self.stand_meter,
      outstanding_bill:     self.outstanding_bill,
      unpaid_bill:          self.unpaid_bill,
      period:               self.period,
      penalty_fee:          self.penalty_fee,
      amount:               self.amount,
      admin_charge:         self.admin_charge,
      bills:                self.bills.as_json({only: [ :bill_period, :penalty_fee, :amount]}),
      info_text:            self.info_text
    }
  end

  def mass_bill_id
    electricity_postpaid_mass_bill&.mass_bill_id
  end

  def biller_product
    nil # currently no biller product for electricity postpaid
  end

  private

  def partner_response_code
    action = "create"
    retrieve_partner_response(product_type, action, partner_name, remote_transaction_id)
  end
end
