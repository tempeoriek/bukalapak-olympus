module Exclusive
  module Transaction
    class BpjsKetenagakerjaanController < ::Exclusive::Transaction::PostpaidsController
      before_action :authorize!

      PRODUCT_NAME = BPJS_KETENAGAKERJAAN_PRODUCT

      def show
        super do |id|
          BpjsKetenagakerjaanTransaction.find_by_id(id)
        end
      end

      def confirm
        super do |remote_transaction_id|
          BpjsKetenagakerjaanTransaction.find_by(remote_transaction_id: remote_transaction_id)
        end
      end

      private

      def authorize!
        raise ::Exceptions::UnauthorizedUser unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
      end
    end
  end
end
