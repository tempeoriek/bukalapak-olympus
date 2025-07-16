module Exclusive
  module Transaction
    class PhoneCreditController < ::Exclusive::Transaction::PostpaidsController
      before_action :authorize!

      PRODUCT_NAME = PHONE_CREDIT_PRODUCT

      def show
        super {
          |id|
            PhoneCreditPostpaidTransaction.find_by_id(id)
        }
      end

      private

      def authorize!
        raise ::Exceptions::UnauthorizedUser.new unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
      end
    end
  end
end
