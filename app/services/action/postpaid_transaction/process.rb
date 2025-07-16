module Action
  module PostpaidTransaction
    class Process
      include PaymentIdHelper
      include PostpaidTransactionUtility

      def initialize(transaction, payment_id = nil)
        @transaction = transaction
        @payment_id = payment_id
      end

      def run!
        @transaction.with_lock do
          if @transaction.pending?
            @transaction.pay!
            record_paid_gmv_and_incr_trx_count
          end
        end


        @transaction.with_lock do
          @transaction.reload
          raise ::Exceptions::CannotProcessTransaction.new unless process_transaction?

          if Toggles::OlympusSievexPredict.active? && eligible_transaction? && not_wiremock?
            sievex_predict_job
          else
            create_partner_transaction_job
          end

          cache_payment_id(@transaction, @payment_id) if cache_payment_id?
          send_notification
        end
      end

      private

      def not_wiremock? # FIXME on another MR
        # most visa numbers defined in wiremock are detected as fraud
        if @transaction.product_type == CREDIT_CARD_BILL_PRODUCT && @transaction.visa?
          return Channel::Config::VISA_WIREMOCK.blank?
        end
        return true
      end

      def cache_payment_id?
        # payment_id is used on agent transaction's push & onsite notification payload
        @transaction.agent? && @payment_id
      end

      def process_transaction?
        @transaction.paid? || (@transaction.processed? && @transaction.partner_transaction_id.nil?)
      end

      def eligible_transaction?
        truth_hash = {
          ELECTRICITY_PRODUCT => false,
          PDAM_PRODUCT => false,
          BPJS_KESEHATAN_PRODUCT => false,
          PDAM_PRODUCT => false,
          CREDIT_CARD_BILL_PRODUCT => true
        }
        truth_hash[@transaction.product_type]
      end

      def sievex_predict_job
        payload = {
          remote_id: @transaction.remote_transaction_id,
          product_type: @transaction.product_type
        }
        GcpsPublisher.publish(Subscribers::Topics::SIEVEX_PREDICT, payload, track_id: payload[:remote_id])
      end

      def create_partner_transaction_job
        product = transaction_product_name(@transaction)
        payload = {
          remote_id: @transaction.remote_transaction_id,
          product_type: @transaction.product_type
        }
        topic_name = is_cc_bill_product(@transaction.product_type) ? Subscribers::Topics::PARTNER_PROCESS_CREDIT_CARD_BILL : Subscribers::Topics::PARTNER_PROCESS
        GcpsPublisher.publish(topic_name, payload, track_id: payload[:remote_id])
      end

      def is_cc_bill_product(product_type)
        product_type == CREDIT_CARD_BILL_PRODUCT
      end

      def send_notification
        # notification on processed only for agent transaction
        return false unless @transaction.agent?
        Action::PostpaidTransaction::SendNotification.new(@transaction).run!
      end

      def record_paid_gmv_and_incr_trx_count
        return unless is_cc_bill_product(@transaction.product_type)

        GeneralCircuitBreaker::CreditCardBill.instance.incr(@transaction.amount)
      end
    end
  end
end
