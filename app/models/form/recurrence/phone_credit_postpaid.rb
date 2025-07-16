module Form
  module Recurrence
    class PhoneCreditPostpaid < Form::Recurrence::Base
      attr_reader :customer_number, :customer_name
      def initialize(params, object, buyer_id, amount = 10000)
        super(params, buyer_id, amount)
        @customer_number = params[:customer_number].gsub(/^0/, '62')
        @customer_name = object.customer_name
      end
    end
  end
end
