module Recurrence
  module BpjsKesehatan
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

        service = Recurrence::BpjsKesehatan::CreateTransaction.new(params[:detail_id])
        result = service.run!

        render_response(recurrence_format(result), 201)
      end

      def notify_balance
        # basic authentication for mothership
        authenticated = http_basic_authenticate
        # this is to avoiding double render
        return unless authenticated == true

        validate_params([:detail_id, :action_date])

        options = { action_date: params[:action_date] }

        service = Recurrence::BpjsKesehatan::Notifier.new('olympus_recurrence_topup_deposit_bpjs_kesehatan_payload', params[:detail_id], options)
        result = service.run!

        render_response({message: 'success'}, 202)
      end

      def notify_stop
        # basic authentication for mothership
        authenticated = http_basic_authenticate
        # this is to avoiding double render
        return unless authenticated == true

        validate_params([:detail_id])

        service = Recurrence::BpjsKesehatan::Notifier.new('olympus_recurrence_unsubscribe_success_bpjs_kesehatan_payload', params[:detail_id])
        result = service.run!

        render_response({message: 'success'}, 202)
      end
    end
  end
end