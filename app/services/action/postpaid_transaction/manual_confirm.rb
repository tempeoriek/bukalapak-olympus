module Action
  module PostpaidTransaction
    class ManualConfirm
      include PostpaidTransactionUtility

      def initialize(transaction)
        @transaction = transaction
      end

      def run!
        case @transaction.state
        when 'succeeded', 'failed', 'partner_succeeded', 'partner_failed'
          update_remote_transaction
        when 'processed'
          confirm_transaction_with_auto_refund
        else
          raise Exceptions::CannotManualConfirmTransaction.new
        end
      end

      private

      def update_remote_transaction
        Action::PostpaidTransaction::UpdateRemote.new(@transaction).run!
      end

      def confirm_transaction_with_auto_refund
        begin
          Action::PostpaidTransaction::Confirm.new(@transaction).run!
        rescue ::Exceptions::PartnerTransactionNotFound => e
          refund_transaction_if_eligible
          raise e
        end
      end

      def refund_transaction_if_eligible
        if ::Toggle::AutoRefundConfirmTransactionNotFound.active? && eligible_autorefund?(@transaction)
          @transaction.partner_fail!
          Action::PostpaidTransaction::UpdateRemote.new(@transaction).run!
          Action::PostpaidTransaction::SendNotification.new(@transaction).run!
        end
      end
    end
  end
end
