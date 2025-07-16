module Recurrence
  module BpjsKesehatan
    class TemplateDetailsController < ApplicationController
      include Response
      include Authenticate

      REQUIRED_PARAMS = %i[customer_number recurrence_value recurrence_type]

      def create
        raise Exceptions::UnauthorizedUser.new if decoded_token[:resource_owner_id] == 0
        params[:phone_number] = decoded_token[:resource_owner][:phone] rescue ''

        validate_params(REQUIRED_PARAMS)
        begin
          today = Time.now
          form = Form::BpjsKesehatan.new(params[:customer_number], nil, today.month, today.year)
          action = Action::PostpaidTransaction::Inquiry.new(form)
          result = action.run!
          amount = result.amount
        rescue ::Exceptions::BillAlreadyPaid => e
          amount = 0
          result = PostpaidTransaction.where(customer_number: params[:customer_number]).last
        end
        recurrence_form = Form::Recurrence::BpjsKesehatan.new(params, result, decoded_token[:resource_owner_id], amount)
        service = Recurrence::BpjsKesehatan::Create.new(recurrence_form)
        result = service.run!

        render_response(result.as_json, 201)
      end

      def show
        result = BpjsKesehatanRecurrenceTemplateDetail.find_by_id(params[:id])
        raise Exceptions::UnauthorizedUser.new unless result.buyer_id == decoded_token[:resource_owner_id] || is_role_authorize?(decoded_token[:resource_owner][:role])

        render_response(result.as_json, 200)
      end
    end
  end
end
