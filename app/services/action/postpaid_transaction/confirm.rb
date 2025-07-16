module Action
  module PostpaidTransaction
    class Confirm
      include PostpaidTransactionUtility

      def initialize(transaction)
        @transaction = transaction
      end

      def run!
        raise ::Exceptions::CannotConfirmTransaction.new unless @transaction.processed?
        raise ::Exceptions::CannotConfirmTransaction.new unless partner_channel.can_confirm?

        response = partner_channel.confirm_transaction

        check_ccb_visa_response(response)

        action = update_transaction_status_action_object(@transaction, response)
        action.run!
      end

      private

      def partner_channel
        @partner_channel ||= Channel.new_partner_channel(@transaction)
      end

      def check_ccb_visa_response(response)
        if @transaction.is_a?(::CreditCardBillTransaction) && @transaction.visa? && response.status != SUCCESS
          raise ::Exceptions::Visa::ConfirmFailed.new('Transaksi tidak ditemukan di sisi partner')
        end
      end

    end
  end
end
