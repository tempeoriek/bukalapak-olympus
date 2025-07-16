class BpjsKesehatanTransaction < ApplicationRecord
  include TransactionStateMachine
  include Postpaid::Constant

  has_many :bpjs_kesehatan_family_members

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
    'dji-bpjs': 1
  }

  enum transaction_type: {
    normal: 0,
    agent: 1,
    procurement: 2,
  }

  validates :buyer_id, presence: true, numericality: { only_integer: true }
  validates :customer_number, presence: true
  validates :amount, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :admin_charge, presence: true, numericality: { only_integer: true }
  validates :payment_period, presence: true
  validates :paid_until, presence: true

  def order_id
    "#{BPJS_KESEHATAN_PREFIX}-#{remote_transaction_id}"
  end

  def product_type
    BPJS_KESEHATAN_PRODUCT
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
    BpjsKesehatanPartner.find_by(name: partner)
  end

  def bill_period
    I18n.l(Date.parse(paid_until + "-01"), format: "%B %Y")
  end

  def month
    paid_until.split('-').second.to_i
  end

  def year
    paid_until.split('-').first.to_i
  end

  # alias
  def family_members
    bpjs_kesehatan_family_members
  end

  def image_url
    'https://s4.bukalapak.com/images/virtual_product/logo_bpjs.png'
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
        :state,
        :amount,
        :admin_charge,
        :customer_number,
        :customer_name,
        :branch_name,
        :family_member_count,
        :payment_period,
        :reference_number,
        :info,
      ]
    )

    year, month = paid_until.split('-')
    result['paid_until'] = {
      'month' => month.to_i,
      'year' => year.to_i
    }
    result['partner'] = partner_hash
    result['family_members'] = family_members.as_json
    result['type'] = Channel::Config::TRANSACTION_TYPE[BPJS_KESEHATAN_PRODUCT]
    result['image_url'] = image_url
    result['transaction_type'] = transaction_type
    result
  end

  def is_mitra?
    transaction_type == AGENT_BUYER_TYPE || transaction_type == COLLECTING_AGENT_BUYER_TYPE
  end

  def biller_product
    nil # currently no biller product for bpjs kesehatan
  end
end
