module Exclusive
  module Transaction
    class CreditCardBillController < ::Exclusive::Transaction::PostpaidsController
      before_action :authorize!

      PRODUCT_NAME = CREDIT_CARD_BILL_PRODUCT

      def show
        super {
          |id|
            CreditCardBillTransaction.find_by_id(id)
        }
      end

      def confirm
        super {
          |remote_transaction_id|
            CreditCardBillTransaction.find_by(remote_transaction_id: remote_transaction_id)
        }
      end

      private

      def authorize!
        raise ::Exceptions::UnauthorizedUser.new unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
      end
    end
  end
end
