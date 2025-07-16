module Subscribers
  class PartnerProcessCcb < Base
    private

    def topic_name
      Subscribers::Topics::PARTNER_PROCESS_CREDIT_CARD_BILL
    end

    def process_task(transaction, options, log_tags)
      begin
        Action::CreditCardBillTransaction::PartnerCreate.new(transaction, options).run!
      rescue Errno::ECONNREFUSED, Errno::ECONNRESET => e
        message = "Retrying payment for #{transaction.product_type}"
        LogBook.warn(message, log_tags, e.backtrace.take(5), track_id: transaction.remote_transaction_id)
        raise e
      rescue StandardError => e
        @should_retry = false
        raise e
      end
    end
  end
end
