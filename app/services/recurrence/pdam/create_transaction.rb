module Recurrence
  module Pdam
    class CreateTransaction < Recurrence::Postpaid::CreateTransaction
      def initialize(template_id)
        super(template_id)
      end

      def run!
        super
      end

      private

      def update_template_detail(result)
        @template_detail.customer_name = result.customer_name
        @template_detail.save!
      end

      def transaction_form
        Form::Pdam.new(template_detail.customer_number, template_detail.operator_id)
      end

      def create_transaction
        action = Action::PdamTransaction::Create.new(transaction_form, template_detail.buyer_id, NORMAL_USER_TRANSACTION_TYPE)
        @transaction = action.run!
        @transaction.template_detail_id = @template_id
        @transaction.save!
        @transaction
      end

      def template_detail
        @template_detail ||= PdamRecurrenceTemplateDetail.find_by_id!(@template_id)
      end

      def postpaid_product
        'pdam'
      end

      def generate_log_message
        {
          buyer_id: template_detail.buyer_id,
          template_detail_id: template_detail.id,
          customer_number: template_detail.customer_number,
          operator_id: template_detail.operator_id
        }
      end
    end
  end
end
