module Action
  module PostpaidTransaction
    class PartnerCreate
      include ::Postpaid::Constant
      include PostpaidTransactionUtility

      DEFAULT_OPTIONS = {
        without_check: false,
        allow_processed: false,
      }

      # TODO: Refactor this to another class!
      # Ayoconnect has different behavior of publishing background jobs when pending.
      AYOCONNECT_JOB_DELAY_SECONDS = 5

      def initialize(transaction, options={})
        @transaction = transaction
        @options = options.reverse_merge(DEFAULT_OPTIONS)
      end

      def run!
        # Reload transaction first
        @transaction.reload

        # Lock intended to ensure that only ONE thread processes one particular trx at a time
        @transaction.with_lock do
          # Validate trx
          error_message = "PartnerCreate only allows `paid` trx state. Use `allow_processed: true` option to allow `processed` trx to use PartnerCreate"
          raise ::Exceptions::TransactionNotPaid.new(error_message) unless should_process?

          # Process
          unless @transaction.processed?
            @transaction.process!
          end
        end

        response = check_transaction || partner_channel.create_transaction
        update_partner_transaction_id!(response)
        delete_quickpay_cache(@transaction)

        case response.status
        when SUCCESS, FAILED
          action = update_transaction_status_action_object(@transaction, response)
          action.run!
        when PENDING
          partner_confirm_transaction_job if partner_channel.can_confirm?
        # TODO
        # when SHOULD_RETRY
        #   requeue_partner_create_allow_processed
        end
      end

      private

      def should_process?
        @transaction.paid? || (@options[:allow_processed] && @transaction.processed?)
      end

      def partner_channel
        @partner_channel ||= Channel.new_partner_channel(@transaction)
      end

      def check_transaction
        return nil if @options[:without_check] || !partner_channel.can_confirm?
        begin
          partner_channel.confirm_transaction
        rescue ::Exceptions::PartnerTransactionNotFound => _e
          nil
        end
      end

      def update_partner_transaction_id!(response)
        @transaction.partner_transaction_id = response.partner_transaction_id
        @transaction.save!
      end

      def update_cc_transaction_detail(response)
        # spesific for credit-card-bill transaction
        rc = ::CreditCardBillTransaction.response_codes.keys.include?(response.response_code) ? response.response_code : "undefined"
        @transaction.response_code = rc
        @transaction.save!
      end

      def partner_confirm_transaction_job
        payload = {
          remote_id: @transaction.remote_transaction_id,
          product_type: @transaction.product_type
        }

        # TODO: Refactor this to another class
        payload.merge!(delay: AYOCONNECT_JOB_DELAY_SECONDS, fixed_delay: true) if @transaction.partner == AYOCONNECT && @transaction.product_type == ELECTRICITY_PRODUCT

        GcpsPublisher.publish(Subscribers::Topics::PARTNER_CONFIRM, payload, track_id: payload[:remote_id])
      end
    end
  end
end
