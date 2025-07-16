module Recurrence
  module Pdam
    class TemplateDetailsController < ApplicationController
      include Response
      include Authenticate

      REQUIRED_PARAMS = %i[customer_number operator_id recurrence_value recurrence_type]

      def create
        raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0

        validate_params(REQUIRED_PARAMS)
        begin
          form = Form::Pdam.new(params[:customer_number], params[:operator_id])
          action = Action::PostpaidTransaction::Inquiry.new(form)
          result = action.run!
          amount = result.amount
        rescue ::Exceptions::BillAlreadyPaid => e
          amount = 0
          result = PdamTransaction.where(customer_number: params[:customer_number]).last
        end
        recurrence_form = Form::Recurrence::Pdam.new(params, result, decoded_token[:resource_owner_id], amount)
        service = Recurrence::Pdam::Create.new(recurrence_form)
        result = service.run!

        render_response(result.as_json, 201)
      end

      def show
        result = PdamRecurrenceTemplateDetail.find_by_id(params[:id])
        raise Exceptions::UnauthorizedUser.new unless result.buyer_id == decoded_token[:resource_owner_id] || is_role_authorize?(decoded_token[:resource_owner][:role])

        render_response(result.as_json, 200)
      end
    end
  end
end
