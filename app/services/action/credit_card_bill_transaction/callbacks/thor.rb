module Action
  module CreditCardBillTransaction
    module Callbacks
      class Thor
        include PostpaidTransactionUtility
        include CachePartnerResponseUtility
        include Channel::Thor::Helpers::ResponseCode

        def initialize(callback)
          @callback = callback
        end

        def run!
          payload = @callback[:credit_card_bill_transaction]

          order_id = payload[:order_id]
          remote_transaction_id = order_id.delete("#{CREDIT_CARD_BILL_PREFIX}-").to_i

          transaction = ::CreditCardBillTransaction.find_by_remote_transaction_id(remote_transaction_id)
          raise ::Exceptions::TransactionNotFound.new if transaction.nil?

          result = ResponseGeneralizer::CreditCardBill.new do |r|
            r.customer_name = payload[:customer_name]
						r.statement_date = payload[:statement_date]
						r.due_date = payload[:due_date]
						r.minimum_payment = payload[:minimum_payment]
            r.partner_financial_journal_number = payload[:financial_journal_number]
            r.partner_journal_number = payload[:journal_number]
            r.reference_number = payload[:reference_number]
            r.status = PARTNER_STATUS[THOR][get_transaction_by_id_status(payload[:response_code]).to_s]
          end

          cache_rc(transaction)

          Action::CreditCardBillTransaction::UpdateStatus.new(transaction, result).run!
        end

        private

        def cache_rc(transaction)
          payload = @callback[:credit_card_bill_transaction]
          status = get_transaction_by_id_status(payload[:response_code]).to_s
          action_name = "callback"
          cache_partner_response(transaction.product_type, action_name, transaction.partner_name, transaction.remote_transaction_id, status)
        end
      end
    end
  end
end
  