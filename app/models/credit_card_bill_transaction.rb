class CreditCardBillTransaction < ApplicationRecord
  include TransactionStateMachine
  include Postpaid::Constant
  include CachePartnerResponseUtility
  include MiddlemanResponseMapperUtility

  belongs_to :credit_card_biller
  belongs_to :credit_card_bill_partner

  MINIMUM_BASE_AMOUNT = 10_000

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

  enum response_code: {
    "success" => 0,
    "timeout" => 1,
    "01" => 2,
    "05" => 3,
    "12" => 4,
    "14" => 5,
    "30" => 6,
    "51" => 7,
    "91" => 8,
    "96" => 9,
    "99" => 10,
    "-2" => 11,
    "5005" => 12,
    "5006" => 13,
    "9000" => 14,
    "9001" => 15,
    "9003" => 16, # Invalid BIN Number
    "undefined" => 17,

    # Visa Internal RC
    "VISA_NO_REF_CODE" => 98, # No Reference Code
    "VISA_NO_TOKEN" => 99, # No token
    # Visa OCT RC
    "VISA_ACCEPTED" => 100,
    "VISA_ERROR" => 101, # The request is missing one or more required fields.
    "VISA_INVALID_REQUEST" => 102, # One or more fields in the request contains invalid data.
    "VISA_100" => 100, # Successful transaction.
    "VISA_101" => 101, # The request is missing one or more required fields.
    "VISA_102" => 102, # One or more fields in the request contains invalid data.
    "VISA_104" => 104, # The merchant reference code for this authorization request matches the merchant reference code of another authorization request that you sent within the past 15 minutes.
    "VISA_150" => 150, # General system failure.
    "VISA_153" => 153, # Your CyberSource account is not enabled for the OCT service.
    "VISA_201" => 201, # The issuing bank has questions about the request. You do not receive an authorization code programmatically, but you might receive one verbally by calling the processor.
    "VISA_202" => 202, # Expired card. You might receive this value if the expiration date you provided does not match the date that the issuing bank has on file.
    "VISA_203" => 203, # General decline of the card. No other information was provided by the issuing bank.
    "VISA_205" => 205, # Stolen or lost card.
    "VISA_208" => 208, # Inactive card or card not authorized for card-not-present transactions.
    "VISA_231" => 231, # Invalid account number.
    "VISA_233" => 233, # General decline by the processor.
    "VISA_234" => 234, # Incorrect information in your CyberSource account.
    "VISA_240" => 240, # The card type sent is invalid or does not correlate with the credit card number.
    "VISA_250" => 250, # The request was received, but a timeout occurred at the payment processor.
    "VISA_490" => 254, # 490 - Your aggregator or acquirer is not accepting transactions from you at this time.
    "VISA_491" => 255, # 491 - Your aggregator or acquirer is not accepting this transaction.
    # Visa Processor RC
    "VISA_00" => 0,  # Successful transaction.
    "VISA_12" => 12, # Issuer declined the transaction.
    "VISA_13" => 13, # Amount exceeded the maximum limit allowed for this type of OCT.
    "VISA_57" => 57, # The cardholder is not set up to receive this type of OCT.
    "VISA_61" => 61, # Issuer declined the transaction because exceeds the cumulative total amount limit.
    "VISA_62" => 62, # Restricted card. OCT cannot be sent to an embargoed country (Cuba, Iran, North Korea, Syria, or Sudan).
    "VISA_64" => 64, # Transaction does not fulfill anti-money laundering requirements because the required sender and recipient information was not sent.
    "VISA_65" => 65, # Issuer declined the transaction because it exceeds the cumulative total count limit.
    "VISA_91" => 91, # Issuer is unavailable.
    "VISA_93" => 93, # Transaction cannot be completed because it violates the law.
    "VISA_94" => 94, # Duplicate transaction.
    "VISA_96" => 96, # Error while performing the transaction.
  }

  enum transaction_type: {
    user: 0,
    agent: 1,
    procurement: 2,
    collecting_agent: 4
  }

  validate :validate_amount
  validates :buyer_id, presence: true, numericality: { only_integer: true }
  validates :customer_number, presence: true
  validates :amount, presence: true, numericality: { only_integer: true }
  validates :bukalapak_admin_charge, presence: true, numericality: { :greater_than_or_equal_to => 0, only_integer: true }
  validates :partner_admin_charge, presence: true, numericality: { only_integer: true }
  validates :invoice_id, allow_blank: true, numericality: { only_integer: true }
  validates :credit_card_biller_id, presence: true
  validates :credit_card_bill_partner_id, presence: true

  def order_id
    "#{CREDIT_CARD_BILL_PREFIX}-#{remote_transaction_id}"
  end

  def product_type
    CREDIT_CARD_BILL_PRODUCT
  end

  def admin_charge
    bukalapak_admin_charge + partner_admin_charge
  end

  def base_amount
    # Amount without admin charge
    amount - admin_charge
  end

  def state_changed_at
    {
      processed_at: processed_at,
      succeeded_at: succeeded_at,
      failed_at: failed_at
    }
  end

  def bill_period
    date = due_date || Date.today
    bill_period = I18n.l(Date.parse(date.to_s), format: "%B %Y")
  end

  def partner_name
    partner&.name
  end

  def partner_hash
    {
      name: PARTNER_OFFICIAL_NAME[partner.name]
    }
  end

  def partner
    credit_card_bill_partner
  end

  def biller
    credit_card_biller
  end

  def recurrent?
    false
  end

  def as_json(_options={})
    result = super(
      only: [
        :id,
        :buyer_id,
        :invoice_id,
        :remote_transaction_id,
        :state,
        :customer_number,
        :customer_name,
        :statement_date,
        :due_date,
        :amount,
        :minimum_payment,
        :transaction_type
      ]
    )
    biller_hash = {
      id: biller.id,
      name: biller.name,
      image_url: biller.image_url
    }
    result['state'] = TRANSACTION_FAILED if self.cancelled?
    result['admin_charge'] = admin_charge
    result['state_changed_at'] = state_changed_at
    result['partner'] = partner_hash
    result['biller'] = biller_hash
    result['type'] = Channel::Config::TRANSACTION_TYPE[CREDIT_CARD_BILL_PRODUCT]
    card_number_to_customer_number(result, _options)
    result['customer_name'] = masked_customer_name
    if self.collecting_agent?
      result['response_code'] = middleman_response_code
      result['failed_reason'] = middleman_failed_reason
    end

    result
  end

  def masked_customer_name
    return '-' if customer_name.nil?
    CreditCardBillHelper.mask_name(customer_name)
  end

  def set_card_number
    return if visa? || cimbniaga_thor?
    # call this after trx record has been saved
    key = generate_key
    plain_text = card_data.to_byte_string

    aes = OpenSSL::Cipher::AES.new(256, :CBC).encrypt
    aes.key = key
    iv_value = aes.random_iv
    aes.iv = iv_value
    result = aes.update(plain_text)
    result << aes.final
    self.card_data = result.unpack('H*')[0]
    self.token = iv_value.unpack('H*')[0]
    self.save!
  end

  def card_number
    return masking_card_number(customer_number) if cimbniaga_thor?
    return customer_number if visa?
    key = generate_key
    plain_text = card_data.to_byte_string

    aes = OpenSSL::Cipher::AES.new(256, :CBC).decrypt
    aes.key = key
    aes.iv = token.to_byte_string
    result = aes.update(plain_text)
    result << aes.final
    result.unpack('H*')[0].scan(/[0-9]+/).first
  end

  def generate_key
    key = created_at.to_i.to_s
    not_so_random_index = id % 10

    second_key = "#{key[1..not_so_random_index]}#{key}#{not_so_random_index}#{key[not_so_random_index..-1]}"
    last_key = "#{second_key[1..not_so_random_index]}#{key}#{not_so_random_index}#{second_key[not_so_random_index..-1]}"
  end

  def validate_amount
    raise Exceptions::InsufficientAmount.new unless base_amount > 0
    if (biller.biller_code == 'BNI' && partner.name == 'bni')
      raise Exceptions::InsufficientAmount.new unless base_amount >= MINIMUM_BASE_AMOUNT && base_amount >= minimum_payment
    else
      raise Exceptions::InsufficientAmount.new unless base_amount >= MINIMUM_BASE_AMOUNT
    end
  end

  def visa?
    partner_name == 'visa'
  end

  def cimbniaga_thor?
    partner_name == 'cimbniaga_thor'
  end

  def is_mitra?
    transaction_type == AGENT_BUYER_TYPE
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

  def middleman_response_code
    retrieve_middleman_response_code(product_type, partner_name, partner_response_code)
  end

  def middleman_failed_reason
    retrieve_middleman_failed_reason(partner_name, partner_response_code)
  end

  def partner_response_code
    # NOTE: pnl saving response code undefined even as state succeeded,
    #   thus we dont depend on the db but on the cached response which
    #   only cached after callback (final action).
    return pnl_response_code if partner_name == PNL
    # For VISA & BNI, there are collided enums so there is slight adjustment for those enums
    retrieve_response_code
  end

  # Maybe fix the enum saved on db not to collide again in the future?
  def retrieve_response_code
    return response_code if partner_name == BNI
    enum_value = self.class.response_codes[response_code]
    case enum_value
    when 0
      "VISA_00"
    when 12
      "VISA_12"
    when 13
      "VISA_13"
    else
      response_code
    end
  end

  def pnl_response_code
    action = 'callback'
    retrieve_partner_response(product_type, action, partner_name, remote_transaction_id)
  end

  def middleman_details
    {
      customer_number:  customer_number,
      customer_name:    masked_customer_name,
      statement_date:   statement_date,
      due_date:         due_date,
      minimum_payment:  minimum_payment,
      biller_name:      biller.name,
      admin_charge:     admin_charge
    }
  end

  def biller_product
    biller&.name
  end

  def masking_card_number(card_number)
    return card_number if card_number.upcase.include? 'X'
    card_number = card_number.gsub("-", "") # make sure the card number not separated by '-'
    masked_card_number = card_number[0..5]+("X"*(card_number.length-10))+card_number[-4..-1]
    masked_card_number.gsub(/(.{4})(?=.)/, '\1-')
  end

  def card_number_to_customer_number(result, _options={})
    is_internal_and_not_collecting_agent = (_options[:internal]) && !self.collecting_agent?
    is_not_exclusive_and_cimbniaga_thor = !(_options[:exclusive]) && cimbniaga_thor? # to make sure in the admin dashboard was not masked

    if is_internal_and_not_collecting_agent || is_not_exclusive_and_cimbniaga_thor
      result['customer_number'] = card_number
    end
  end
end
