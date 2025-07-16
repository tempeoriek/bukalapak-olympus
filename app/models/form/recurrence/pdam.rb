module Form
  module Recurrence
    class Pdam < Form::Recurrence::Base
      attr_reader :customer_number, :customer_name, :operator_id
      def initialize(params, object, buyer_id, amount)
        super(params, buyer_id, amount)
        @customer_number = params[:customer_number]
        @customer_name = object.customer_name
        @operator_id = params[:operator_id]
      end
    end
  end
end
