module Recurrence
  module PhoneCreditPostpaid
    class InternalController < ApplicationController
      include ::Postpaid::Constant
      include Response
      include Authenticate

      def create
        # basic authentication for mothership
        authenticated = http_basic_authenticate
        # this is to avoiding double render
        return unless authenticated == true

        validate_params([:detail_id])

        result = Recurrence::PhoneCreditPostpaid::CreateTransaction.new(params[:detail_id]).run!

        render_response(recurrence_format(result), 201)
      end

      def notify_balance
        # basic authentication for mothership
        authenticated = http_basic_authenticate
        # this is to avoiding double render
        return unless authenticated == true

        validate_params([:detail_id])

        template = PhoneCreditPostpaidRecurrenceTemplateDetail.find_by_id!(params[:detail_id])
        return render_error(Exceptions::TemplateNotFound.new) if template.nil?

        Recurrence::PhoneCreditPostpaid::Notifier.reminder(template)

        render_response({ message: 'success' }, 202)
      end

      def notify_stop
        # basic authentication for mothership
        authenticated = http_basic_authenticate
        # this is to avoiding double render
        return unless authenticated == true

        validate_params([:detail_id])

        template = PhoneCreditPostpaidRecurrenceTemplateDetail.find_by_id!(params[:detail_id])
        return render_error(Exceptions::TemplateNotFound.new) if template.nil?

        Recurrence::PhoneCreditPostpaid::Notifier.stop_subscribing(template)

        render_response({ message: 'success' }, 202)
      end
    end
  end
end