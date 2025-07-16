module Recurrence
  module ElectricityPostpaid
    class Create < Recurrence::Postpaid::Create
      def initialize(form)
        super(form)
        @customer_number = form.customer_number
        @customer_name = form.customer_name
        @power = form.power
        @segmentation = form.segmentation
      end

      def run!
        super()
      end

      private

      def postpaid_product
        'electricity_postpaid'
      end

      def template_detail_klass_instance
        ElectricityPostpaidRecurrenceTemplateDetail.new
      end

      def set_template_detail
        @template.buyer_id = @buyer_id
        @template.customer_number = @customer_number
        @template.customer_name = @customer_name
        @template.power = @power
        @template.segmentation = @segmentation
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
        service = Recurrence::ElectricityPostpaid::Notifier.new('olympus_recurrence_subscribe_success_postpaid_electricity_payload', @template.id, { action_date: action_date })
        result = service.run!
      end
    end
  end
end
