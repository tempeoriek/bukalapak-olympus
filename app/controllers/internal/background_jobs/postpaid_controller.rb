module Internal
  module BackgroundJobs
    class PostpaidController < Internal::PostpaidController
      include Response
      include Authenticate
      include PostpaidTransactionUtility
      include LoggerUtility
      include SepulsaGeneralizeable

      def transaction_create
        return unless http_basic_authenticate

        # extract variables
        transaction_id = params[:transaction_id]
        product_name = params[:product]
        options = params[:options] || {}

        # act
        transaction = find_transaction_by(transaction_id, product_name)
        res = Action::PostpaidTransaction::PartnerCreate.new(transaction, options).run!

        render_response(transaction.as_json, 200)
      end

      def transaction_confirm
        return unless http_basic_authenticate

        # extract variables
        transaction_id = params[:transaction_id]
        product_name = params[:product]

        # act
        transaction = find_transaction_by(transaction_id, product_name)

        ## Validate transaction
        case transaction.state
        when 'processed'
          Action::PostpaidTransaction::Confirm.new(transaction).run!
        when 'pending'
          others[:severity] = 'WARNING'
          warn_worker_log("#{product_name} - confirming a 'pending' transaction, please check any system anomalities", ['worker', 'action', 'confirm', 'warning'], others)
        when 'succeeded', 'failed'
          info_worker_log("#{product_name} - confirming a '#{transaction.state}' transaction (final state), trx has possibly been callbacked", ['worker', 'action', 'confirm', 'info'], others)
        end

        render_response(transaction.as_json, 200)
      end

      def transaction_send_email
        return unless http_basic_authenticate
        # extract variables
        product_name = params[:product]

        # act
        transaction = find_transaction_by(params['transaction_id'], product_name)
        res = Escrow::SendNotification.new(transaction).run!

        render_response(transaction.as_json, 200)
      end

      def transaction_update_remote
        return unless http_basic_authenticate
        # extract variables
        transaction_id = params[:transaction_id]
        product_name = params[:product]

        # act
        transaction = find_transaction_by(transaction_id, product_name)
        res = Escrow::UpdateTransactionStatus.new(transaction).run!

        render_response(transaction.as_json, 200)
      end

      def transaction_callback_sepulsa
        return unless http_basic_authenticate
        # extract variables
        remote_transaction_id = params[:order_id].split('-').second.to_i
        product_name = params[:product]

        # act
        transaction = find_transaction_by_remote_transaction_id(remote_transaction_id, product_name)
        response_generalizer = sepulsa_response_generalizer(params, product_name)
        res = update_transaction_status_action_object(transaction, response_generalizer).run!

        render_response(transaction.as_json, 200)
      end

      def transaction_sievex_predict
        return unless http_basic_authenticate
        # extract variables
        transaction_id = params[:transaction_id]
        product_name = params[:product]

        # act
        transaction = find_transaction_by(transaction_id, product_name)
        res = Action::PostpaidTransaction::SievexPredict.new(transaction).run!

        render_response(transaction.as_json, 200)
      end

      def user_deleted
        return unless http_basic_authenticate

        form = Form::Anonymization.new(params)
        raise ::Exceptions::InvalidParameterError.new unless form.valid?

        ::Services::AnonymizationData.new(params[:user_id]).perform

        render_response({message: 'success'}, 200)
      end
    end
  end
end
