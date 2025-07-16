module Subscribers
  class PartnerConfirm < Base
    private

    def topic_name
      Subscribers::Topics::PARTNER_CONFIRM
    end

    def process_task(transaction, options, log_tags)
      case transaction.state
      when 'pending'
        message = "confirming a 'pending' #{transaction.product_type} transaction, please check any system anomalities"
        LogBook.warn(message, log_tags, track_id: transaction.remote_transaction_id)
      when 'succeeded', 'failed'
        message = "confirming a '#{transaction.state}' #{transaction.product_type} transaction (final state), trx has possibly been callbacked"
        LogBook.warn(message, log_tags, track_id: transaction.remote_transaction_id)
      when 'processed'
        Action::PostpaidTransaction::Confirm.new(transaction).run!
      end
    end
  end
end
