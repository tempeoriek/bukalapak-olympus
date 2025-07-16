module Action
  module PostpaidTransaction
    class UpdateRemote
      include PostpaidTransactionUtility

      def initialize(transaction)
        @transaction = transaction
      end

      def run!
        product = transaction_product_name(@transaction)
        payload = {
          remote_id: @transaction.remote_transaction_id,
          product_type: @transaction.product_type
        }
        GcpsPublisher.publish(Subscribers::Topics::UPDATE_REMOTE, payload, track_id: payload[:remote_id])
      end

    end
  end
end
