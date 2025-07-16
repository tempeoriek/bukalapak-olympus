# frozen_string_literal: true

module Sievex
  class Base
    include PostpaidTransactionUtility
    include LoggerUtility

    URL = "#{ENV['SIEVEX_HOST']}/_internal/v1/events"
    AUTH = Base64.strict_encode64("#{ENV['SIEVEX_USERNAME']}:#{ENV['SIEVEX_PASSWORD']}")
    USER = 'User'

    CREDIT_CARD_BILL_ENTITY = 'credit_card_bill_transaction'

    EVENT_TYPE_MAP = {
      pending: 'CREATE',
      paid: 'PAY',
      cancelled: 'CANCEL',
      expired: 'EXPIRE',
      processed: 'PROCESS',
      partner_succeeded: 'SUCCESS',
      partner_fail: 'FAIL',
      succeeded: 'REMIT',
      failed: 'REFUND'
    }.freeze

    ENTITY_TYPE_MAP = {
      ::CreditCardBillTransaction => CREDIT_CARD_BILL_ENTITY
    }.freeze
  end
end