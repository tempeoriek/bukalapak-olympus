module PostpaidTransactionUtility
  include Postpaid::Constant

  PRODUCT_TO_TRX_KLASS_MAP = {
    ELECTRICITY_PRODUCT => ::PostpaidTransaction,
    BPJS_KESEHATAN_PRODUCT => ::BpjsKesehatanTransaction,
    BPJS_KETENAGAKERJAAN_PRODUCT => ::BpjsKetenagakerjaanTransaction,
    PDAM_PRODUCT => ::PdamTransaction,
    PHONE_CREDIT_PRODUCT => ::PhoneCreditPostpaidTransaction,
    CREDIT_CARD_BILL_PRODUCT => ::CreditCardBillTransaction,
  }

  TRX_KLASS_TO_PRODUCT_MAP = {
    ::PostpaidTransaction => ELECTRICITY_PRODUCT,
    ::BpjsKesehatanTransaction => BPJS_KESEHATAN_PRODUCT,
    ::BpjsKetenagakerjaanTransaction => BPJS_KETENAGAKERJAAN_PRODUCT,
    ::PdamTransaction => PDAM_PRODUCT,
    ::PhoneCreditPostpaidTransaction => PHONE_CREDIT_PRODUCT,
    ::CreditCardBillTransaction => CREDIT_CARD_BILL_PRODUCT,
  }

  TRX_TO_ACTION_MODULE_MAP = {
    ::BpjsKesehatanTransaction => Action::BpjsKesehatanTransaction,
    ::BpjsKetenagakerjaanTransaction => Action::BpjsKetenagakerjaanTransaction,
    ::PostpaidTransaction => Action::ElectricityTransaction,
    ::PdamTransaction => Action::PdamTransaction,
    # currently PhoneCreditPostpaidTransaction is directed here
    # since it doesn't have any UpdateStatus class, it uses
    # Action::PostpaidTransaction instead.
    ::PhoneCreditPostpaidTransaction => Action::PostpaidTransaction,
    ::CreditCardBillTransaction => Action::CreditCardBillTransaction,
  }

  AUTOREFUND_ELIGIBLE_ELECTRICITY = %w[ayoconnect ayoconnect_bukaconnect]

  # TODO Refactor: Move this method as transaction's mixin instead
  def transaction_product_name(transaction)
    product_name = TRX_KLASS_TO_PRODUCT_MAP[transaction.class]
    raise 'Unsupported Type' unless product_name

    product_name
  end

  def recurrence_notifier(transaction)
    if transaction.class == PostpaidTransaction
      {
        klass: Recurrence::ElectricityPostpaid::Notifier,
        payload_name: 'postpaid_electricity'
      }
    elsif transaction.class == PdamTransaction
      {
        klass: Recurrence::Pdam::Notifier,
        payload_name: 'pdam'
      }
    elsif transaction.class == BpjsKesehatanTransaction
      {
        klass: Recurrence::BpjsKesehatan::Notifier,
        payload_name: 'bpjs_kesehatan'
      }
    else
      raise 'Unsupported Type'
    end
  end

  def find_transaction_by(id, product_name)
    trx_klass = PRODUCT_TO_TRX_KLASS_MAP[product_name]
    raise "not supported product type `#{product_name}`" unless trx_klass

    trx_klass.find(id)
  end

  def find_transaction_by_remote_transaction_id(id, product_name)
    trx_klass = PRODUCT_TO_TRX_KLASS_MAP[product_name]
    raise "not supported product type `#{product_name}`" unless trx_klass

    trx_klass.find_by_remote_transaction_id(id)
  end

  def get_product_name_from_product_id(product_id)
    if product_id == ENV['POSTPAID_PRODUCT'].to_i
      ELECTRICITY_PRODUCT
    elsif product_id == ENV['BPJS_KESEHATAN_PRODUCT'].to_i
      BPJS_KESEHATAN_PRODUCT
    elsif product_id == ENV['PDAM_PRODUCT'].to_i
      PDAM_PRODUCT
    else
      raise 'Unsupported Type'
    end
  end

  def notif_bill_period(transaction)
    product_name = transaction_product_name(transaction)
    if [ELECTRICITY_PRODUCT, PDAM_PRODUCT].include? product_name
      bills = product_name == PDAM_PRODUCT ? transaction.pdam_bills : transaction.bills

      first_bill_period = I18n.l(Date.parse(bills.first.bill_period.to_s), format: "%B %Y")
      last_bill_period = I18n.l(Date.parse(bills.last.bill_period.to_s), format: "%B %Y")
      bill_period = 'periode ' + (first_bill_period == last_bill_period ? first_bill_period : first_bill_period + ' - ' + last_bill_period)
    elsif product_name == BPJS_KESEHATAN_PRODUCT
      #BPJS bill period format is a 'yyyy-MM' string
      bill_period = 'sampai periode ' + I18n.l(Date.parse(transaction.paid_until + '-01'), format: "%B %Y")
    else
      raise 'not supported product type'
    end
    bill_period
  end

  # TODO Refactor: Move this method as transaction's mixin instead
  def generate_remote_type(transaction)
    product_name = transaction_product_name(transaction)
    ::Channel::Config::TRANSACTION_TYPE[product_name]
  end

  def delete_quickpay_cache(transaction)
    operator = transaction.operator rescue nil
    biller = transaction.biller rescue nil

    Quickpays::Delete.new(
      transaction.product_type,
      Time.now,
      transaction.buyer_id,
      { customer_number: transaction.customer_number,
        operator: operator,
        biller: biller
      }.compact
    ).run!
  end

  def log_request(tags, message, track_id = nil, opts={})
    opts[:track_id] = track_id.to_s unless track_id.nil?
    log_entry = ::Context.new.log_entry(message, tags, opts)
    Logger2.info(log_entry)
  end

  def log_error(tags, message, track_id, opts={})
    opts[:track_id] = track_id.to_s unless track_id.nil?
    log_entry = ::Context.new.log_entry(message, tags, opts)
    Logger2.error(log_entry)
  end

  def get_partner_klass(partner)
    raise NotImplementedError.new
  end

  # TODO Refactor: Move this method as transaction's mixin instead
  def update_transaction_status_action_object(transaction, response_generalizer)
    product_action_module = TRX_TO_ACTION_MODULE_MAP[transaction.class]
    raise 'not supported product type' unless product_action_module

    product_action_module::UpdateStatus.new(transaction, response_generalizer)
  end

  def eligible_autorefund?(transaction)
    return false if transaction.nil?
    return false unless transaction.processed_at <= 3.hours.ago

    case transaction
    when PostpaidTransaction
      return transaction.partner_object.name.in?(AUTOREFUND_ELIGIBLE_ELECTRICITY)
    else
      return false
    end
  end
end
