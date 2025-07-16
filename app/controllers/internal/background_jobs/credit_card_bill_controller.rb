module Internal
  module BackgroundJobs
    class CreditCardBillController < Internal::PostpaidController
      include Response
      include Authenticate
      include PostpaidTransactionUtility
      include LoggerUtility

      PRODUCT_NAME = CREDIT_CARD_BILL_PRODUCT

      def transaction_create
        return unless http_basic_authenticate

        # extract variables
        transaction_id = params[:transaction_id]
        product_name = params[:product]
        options = params[:options] || {}
        retry_count = params[:retry_count]

        # act
        transaction = find_transaction_by(transaction_id, product_name)

        begin
          Action::CreditCardBillTransaction::PartnerCreate.new(transaction, options).run!
        rescue Errno::ECONNREFUSED, Errno::ECONNRESET => e
          # retry by sending 502 error
          warn_worker_log("Retry \##{retry_count} #{product_name} - #{e.message}", ['worker', product_name.underscore, 'create', "retry_#{retry_count}"])
          error_message = "Cannot connect to bts kube, retrying trx with remote id `#{transaction.remote_transaction_id}`"
          return render_error(Exceptions::BtsKube::CannotConnectToBtsKube.new(error_message))
        end

        render_response(transaction.as_json, 200)
      end

    end
  end
end
