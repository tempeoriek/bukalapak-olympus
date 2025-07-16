module Recurrence
  module Pdam
    class Create < Recurrence::Postpaid::Create
      def initialize(form)
        super(form)
        @customer_number = form.customer_number
        @customer_name = form.customer_name
        @operator_id = form.operator_id
      end

      def run!
        super()
      end

      private

      def postpaid_product
        'pdam'
      end

      def template_detail_klass_instance
        PdamRecurrenceTemplateDetail.new
      end

      def set_template_detail
        @template.buyer_id = @buyer_id
        @template.customer_number = @customer_number
        @template.customer_name = @customer_name
        @template.operator_id = @operator_id
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
          operator_id: @operator_id,
          buyer_id: @buyer_id
        }
      end

      def notify_subscribe
        service = Recurrence::Pdam::Notifier.new('olympus_recurrence_subscribe_success_pdam_payload', @template.id, { action_date: action_date })
        result = service.run!
      end
    end
  end
end
