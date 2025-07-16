module Recurrence
  module PhoneCreditPostpaid
    class PublicController < ApplicationController
      include Response
      include Authenticate

      REQUIRED_PARAMS = %i[customer_number recurrence_value recurrence_type]

      def create
        raise Exceptions::UnauthorizedUser.new unless decoded_token

        validate_params(REQUIRED_PARAMS)

        form = Form::PhoneCredit.new(params[:customer_number], nil, RECURRENCE_ELIGIBLE_BUYER_TYPE)

        res = valid_recurring_number?(form)
        return render_error(res) if res.is_a? StandardError

        buyer_id = decoded_token[:resource_owner_id]
        r_form = Form::Recurrence::PhoneCreditPostpaid.new(params, res, buyer_id)
        result = Recurrence::PhoneCreditPostpaid::Create.new(r_form).run!

        render_response(result.as_json, 201)
      end

      def show
        result = PhoneCreditPostpaidRecurrenceTemplateDetail.find_by_id(params[:id])

        raise Exceptions::UnauthorizedUser.new unless decoded_token && ( result.buyer_id == decoded_token[:resource_owner_id] || is_role_authorize?(decoded_token[:resource_owner][:role]) )

        render_response(result.as_json, 200)
      end

      private

      def valid_recurring_number?(form)
        Action::PostpaidTransaction::Inquiry.new(form).run!
      rescue ::Exceptions::BillAlreadyPaid
        return ResponseGeneralizer::PhoneCreditPostpaid.new
      rescue ::Exceptions::PostpaidError, ::Exceptions::InternalError => e
        return e
      rescue
        raise
      end
    end
  end
end
