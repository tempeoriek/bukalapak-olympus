module Recurrence
  module Postpaid
    class CreateTransaction
      include PostpaidTransactionUtility
      include ::Postpaid::Constant

      def initialize(template_id)
        @template_id = template_id
      end

      def run!
        ## This transaction locks Keystore.increment
        # ActiveRecord::Base.transaction do
        result = create_transaction
        # update_template_detail may fail while trx has already been registered
        update_template_detail(result)
        # end

        log_request([postpaid_product, 'transaction', 'recurrence', 'create', 'success'], generate_log_message, @template_id)
        Observer.counter(Observer::Metric::RECURRENCE, 1, status: 'ok', product: postpaid_product)

        @transaction
      rescue => e # log the error
        log_request([postpaid_product, 'transaction', 'recurrence', 'create', 'failed'], generate_error_log_message(e))
        Observer.counter(Observer::Metric::RECURRENCE, 1, status: 'fail', product: postpaid_product)

        Honeybadger.notify(e)
        raise
      end

      private

      def update_template_detail(result)
        raise NotImplementedError
      end

      def transaction_form
        raise NotImplementedError
      end

      def create_transaction
        raise NotImplementedError
      end

      def template_detail
        raise NotImplementedError
      end

      def postpaid_product
        raise NotImplementedError
      end

      def generate_log_message
        raise NotImplementedError
      end

      def generate_error_log_message(e)
        log_message = generate_log_message
        log_message[:error] = {
          message: e&.message,
          backtrace: e&.backtrace.take(7).join("\n")
        }
        log_message
      end

      def get_user_deposit
        response = Escrow::RetrieveDeposit.new(template_detail.buyer_id).run!
        response[:withdrawable_balance]
      end
    end
  end
end
