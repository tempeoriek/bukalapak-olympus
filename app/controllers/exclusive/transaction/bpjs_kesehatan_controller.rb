module Exclusive
  module Transaction
    class BpjsKesehatanController < ::Exclusive::Transaction::PostpaidsController
      before_action :authorize!

      PRODUCT_NAME = BPJS_KESEHATAN_PRODUCT

      def show
        super {
          |id|
            BpjsKesehatanTransaction.find_by_id(id)
        }
      end

      def confirm
        super {
          |remote_transaction_id|
            BpjsKesehatanTransaction.find_by(remote_transaction_id: remote_transaction_id)
        }
      end

      def show_by_customer_number
        result = []
        transactions = []
        total = 0

        if !params[:customer_numbers].nil? && !params[:customer_numbers].empty?
          customer_numbers = JSON.parse(params[:customer_numbers])
          limit = params[:limit]&.to_i || 10
          offset = params[:offset]&.to_i || 0

          total = BpjsKesehatanTransaction.where(customer_number: customer_numbers).count
          transactions = BpjsKesehatanTransaction.where(customer_number: customer_numbers)
                                                 .order(created_at: :desc)
                                                 .limit(limit)
                                                 .offset(offset)
        end

        transactions.each do |transaction|
          result << transaction.as_json
        end

        render_response_with_paginantion(result, 200, {http_status: 200, limit: limit, offset: offset, total: total})
      end

      private

      def authorize!
        raise ::Exceptions::UnauthorizedUser.new unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
      end
    end
  end
end
