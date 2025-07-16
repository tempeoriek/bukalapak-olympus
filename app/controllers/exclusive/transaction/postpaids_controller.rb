module Exclusive
  module Transaction
    class PostpaidsController < ::ApplicationController
      include Postpaid::Constant
      include Response
      include Authenticate

      REQUIRED_PARAMS = %i[id]

      def confirm(&block)
        validate_params(REQUIRED_PARAMS)

        transaction = block.call(params[:id])
        raise Exceptions::TransactionNotFound.new unless transaction.present?

        action = Action::PostpaidTransaction::ManualConfirm.new(transaction)
        action.run!

        render_response(transaction.as_json, 200)
      end

      def show(&block)
        transaction = block.call(params[:id])
        raise Exceptions::TransactionNotFound.new unless transaction.present?

        render_response(transaction.as_json({exclusive: true}), 200)
      end
    end
  end
end
