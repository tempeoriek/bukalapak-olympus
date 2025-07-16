module Action
  module PostpaidTransaction
    class UpdateStatus
      include PostpaidTransactionUtility

      def initialize(transaction, response)
        @transaction = transaction
        @response = response
      end

      def run!
        update_transaction_id!

        raise ::Exceptions::InvalidStatusError.new("Status not valid, given `#{@response.status}`") unless [SUCCESS, FAILED].include? @response.status

        if @response.status == SUCCESS
          update_succeeded_transaction!
          @transaction.partner_success!
          enqueue_success_transaction_to_mws!
        elsif @response.status == FAILED
          update_failed_transaction!
          @transaction.partner_fail!
        end

        Action::PostpaidTransaction::UpdateRemote.new(@transaction).run!
        Action::PostpaidTransaction::SendNotification.new(@transaction).run!

        @transaction
      end

      private

      def update_transaction_id!
        @transaction.partner_transaction_id = @response.partner_transaction_id
        @transaction.save!
      end

      def update_succeeded_transaction!
        nil
      end

      def update_failed_transaction!
        nil
      end

      def enqueue_success_transaction_to_mws!
        nil
      end
    end
  end
end
