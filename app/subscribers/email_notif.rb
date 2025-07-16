module Subscribers
  class EmailNotif < Base
    private

    def topic_name
      Subscribers::Topics::EMAIL_NOTIF
    end

    def process_task(transaction, options, log_tags)
      if Keystore.get(ELECTRICITY_EMAIL_TELOLET_TOGGLE) && transaction.product_type == ELECTRICITY_PRODUCT
        send_email(transaction)
      elsif Keystore.get(EMAIL_TELOLET_TOGGLE)
        send_email(transaction)
      else
        Escrow::SendNotification.new(transaction).run!
      end
    end

    def send_email(transaction)
      if transaction.recurrent?
        send_recurrent_email(transaction)
      else
        Action::PostpaidTransaction::EmailNotif.new(transaction).run!
      end
    end

    def send_recurrent_email(transaction)
        recurrence_notifier_object = recurrence_notifier(transaction)
        bukalapak_state = TRX_STATE_TO_BL_STATE_MAP[transaction.state]
        state_template = BL_STATE_TO_TEMPLATE_MAP[bukalapak_state]

        options = { amount: transaction.amount, remote_id: transaction.id, invoice_id: transaction.invoice_id }

        service = recurrence_notifier_object[:klass].new("olympus_recurrence_transaction_#{state_template}_#{recurrence_notifier_object[:payload_name]}_payload", transaction.template_detail_id, options)
        service.run!
    end
  end
end
