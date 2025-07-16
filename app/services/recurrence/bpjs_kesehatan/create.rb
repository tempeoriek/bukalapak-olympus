module Recurrence
  module BpjsKesehatan
    class Create < Recurrence::Postpaid::Create

      def initialize(form)
        super(form)
        @customer_number = form.customer_number
        @customer_name = form.customer_name
        @phone_number = form.phone_number
        @family_member_count = form.family_member_count
      end

      def run!
        super()
      end

      private

      def postpaid_product
        'bpjs-kesehatan'
      end

      def template_detail_klass_instance
        BpjsKesehatanRecurrenceTemplateDetail.new
      end

      def set_template_detail
        @template.buyer_id = @buyer_id
        @template.customer_number = @customer_number
        @template.customer_name = @customer_name
        @template.phone_number = @phone_number
        @template.family_member_count = @family_member_count
        @template.save!
      end

      def generate_error_log_message(e)
        log_message = generate_log_message
        log_message[:error] = {
          message: e&.message,
          backtrace: e&.backtrace.take(7).join("\n")
        }
        log_message
      end

      def generate_log_message
        {
          customer_number: @customer_number,
          recurrence_value: @recurrence_value,
          recurrence_type: @recurrence_type,
          buyer_id: @buyer_id
        }
      end

      def notify_subscribe
        service = Recurrence::BpjsKesehatan::Notifier.new('olympus_recurrence_subscribe_success_bpjs_kesehatan_payload', @template.id, { action_date: action_date })
        result = service.run!
      end
    end
  end
end
