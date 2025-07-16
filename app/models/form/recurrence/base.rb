module Form
  module Recurrence
    class Base
      attr_reader :recurrence_type, :recurrence_value, :payment_method, :buyer_id, :amount, :action_date
      def initialize(params, buyer_id, amount)
        @recurrence_value = params[:recurrence_value]
        @recurrence_type = params[:recurrence_type]
        @payment_method = params[:payment_method]
        @action_date = params[:action_date]
        @buyer_id = buyer_id
        @amount = amount
      end
    end
  end
end
