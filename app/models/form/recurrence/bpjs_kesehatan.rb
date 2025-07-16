module Form
  module Recurrence
    class BpjsKesehatan < Form::Recurrence::Base
      attr_reader :customer_number, :customer_name, :phone_number, :family_member_count
      def initialize(params, object, buyer_id, amount)
        super(params, buyer_id, amount)
        @customer_name = object&.customer_name
        @customer_number = params[:customer_number]
        @phone_number = params[:phone_number]
        @family_member_count = object&.family_member_count
      end
    end
  end
end
