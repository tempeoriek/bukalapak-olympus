module Recurrence
  module PhoneCreditPostpaid
    class Create < Recurrence::Postpaid::Create
      def initialize(form)
        super(form)
        @customer_number = form.customer_number
        @customer_name = form.customer_name
      end

      def run!
        super
      end

      private

      def postpaid_product
        'phone-credit-postpaid'
      end

      def template_detail_klass_instance
        PhoneCreditPostpaidRecurrenceTemplateDetail.new
      end

      def set_template_detail
        @template.buyer_id = @buyer_id
        @template.customer_number = @customer_number
        @template.customer_name = @customer_name unless @customer_name.nil?
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
        Notifier.subscribe_success(@template)
      end
    end
  end
end
