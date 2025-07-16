module Action
  module CreditCardBillTransaction
    class PartnerCreate
      include PostpaidTransactionUtility

      KODE_LOKET = Channel::Config::BNI_KODE_LOKET.freeze
      DEFAULT_OPTIONS = {
        without_check: false
      }

      def initialize(transaction, options={})
        @transaction = transaction
        @options = options.reverse_merge(DEFAULT_OPTIONS)
      end

      def run!
        ActiveRecord::Base.transaction do
          @transaction.reload
          check_and_update_reffnum if @transaction.partner_name == 'bni'
          @transaction.process! if @transaction.paid?
        end

        response = partner_channel.create_transaction

        update_transaction_detail(response)

        delete_quickpay_cache(@transaction)

        case response.status
        when SUCCESS, FAILED
          action = update_transaction_status_action_object(@transaction, response)
          action.run!
        when PROCESS # async
          partner_confirm_transaction_job
        end
      end

      private

      def partner_confirm_transaction_job
        payload = {
          remote_id: @transaction.remote_transaction_id,
          product_type: @transaction.product_type
        }
        GcpsPublisher.publish(Subscribers::Topics::PARTNER_CONFIRM, payload, track_id: payload[:remote_id])
      end

      def partner_channel
        @partner_channel ||= Channel.new_partner_channel(@transaction)
      end

      def check_and_update_reffnum
        raise ::Exceptions::CannotProcessTransaction.new unless allow_process?
        raise ::Exceptions::DoubleValueError.new("reference_number") unless @transaction.reference_number.nil?

        reffnum = generate_reference_number
        @transaction.update!({reference_number: reffnum})
      end

      def update_transaction_detail(response)
        ActiveRecord::Base.transaction do
          @transaction.lock!
          rc = ::CreditCardBillTransaction.response_codes.keys.include?(response.response_code) ? response.response_code : "undefined"
          @transaction.partner_transaction_id = response.partner_transaction_id
          @transaction.response_code = rc
          @transaction.reference_number = response.reference_number if @transaction.visa?
          @transaction.save!
        end

        # TODO should this be put inside transaction block in update_transaction_detail method?
        # Potential problem: table lock wait timeout error
        DeleteToken.new(@transaction).run!
      end

      def allow_process?
        @transaction.paid? || @transaction.processed?
      end

      def generate_reference_number
        date = Time.now.in_time_zone.strftime("%Y%m%d%H%M%S%5N")
        "#{date}#{Random.rand(10)}#{KODE_LOKET}"
      end
    end
  end
end
