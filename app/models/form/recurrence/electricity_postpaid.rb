module Form
  module Recurrence
    class ElectricityPostpaid < Form::Recurrence::Base
      attr_reader :customer_number, :customer_name, :power, :segmentation
      def initialize(params, object, buyer_id, amount)
        # object can be object transaction or ResponseGeneralizer
        super(params, buyer_id, amount)
        @customer_number = params[:customer_number]
        @customer_name = object&.customer_name
        @power = object&.power
        @segmentation = object&.segmentation
      end
    end
  end
end
