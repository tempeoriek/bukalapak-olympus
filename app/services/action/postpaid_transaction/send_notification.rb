module Action
  module PostpaidTransaction
    class SendNotification
      include PostpaidTransactionUtility

      def initialize(transaction)
        @transaction = transaction
        @product_name = transaction_product_name(transaction)
        @bukalapak_state = TRX_STATE_TO_BL_STATE_MAP[transaction.state]
      end

      def run!
        send_email
        send_push_notif
        send_onsite_notif
      end

      private

      def send_email?
        # send email on remitted or failed
        Toggles::EmailNotif.active? && @bukalapak_state != BUKALAPAK_PROCESSED
      end

      def send_email
        return false unless send_email?

        payload = {
          remote_id: @transaction.remote_transaction_id,
          product_type: @transaction.product_type
        }
        GcpsPublisher.publish(Subscribers::Topics::EMAIL_NOTIF, payload, track_id: payload[:remote_id])

      end

      def send_push_notif
        return false unless Toggles::PushNotif.active?
        if @product_name == ELECTRICITY_PRODUCT
          Action::ElectricityTransaction::PushNotif.new(@transaction, @bukalapak_state).run!
        elsif @product_name == BPJS_KESEHATAN_PRODUCT
          Action::BpjsKesehatanTransaction::PushNotif.new(@transaction, @bukalapak_state).run!
        elsif @product_name == PDAM_PRODUCT
          Action::PdamTransaction::PushNotif.new(@transaction, @bukalapak_state).run!
        elsif @product_name == PHONE_CREDIT_PRODUCT
          Action::PhoneCreditTransaction::PushNotif.new(@transaction, @bukalapak_state).run!
        elsif @product_name == CREDIT_CARD_BILL_PRODUCT
          Action::CreditCardBillTransaction::PushNotif.new(@transaction, @bukalapak_state).run!
        end
      end

      def send_onsite_notif
        return false unless Toggles::OnSiteNotif.active?
        if @product_name == ELECTRICITY_PRODUCT
          Action::ElectricityTransaction::OnsiteNotif.new(@transaction, @bukalapak_state).run!
        elsif @product_name == BPJS_KESEHATAN_PRODUCT
          Action::BpjsKesehatanTransaction::OnsiteNotif.new(@transaction, @bukalapak_state).run!
        elsif @product_name == PDAM_PRODUCT
          Action::PdamTransaction::OnsiteNotif.new(@transaction, @bukalapak_state).run!
        elsif @product_name == PHONE_CREDIT_PRODUCT
          Action::PhoneCreditTransaction::OnsiteNotif.new(@transaction, @bukalapak_state).run!
        elsif @product_name == CREDIT_CARD_BILL_PRODUCT
          Action::CreditCardBillTransaction::OnsiteNotif.new(@transaction, @bukalapak_state).run!
        end
      end
    end
  end
end
