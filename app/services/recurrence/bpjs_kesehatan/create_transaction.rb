module Recurrence
  module BpjsKesehatan
    class CreateTransaction < Recurrence::Postpaid::CreateTransaction

      def initialize(template_id)
        super(template_id)
      end

      def run!
        super
      end

      private

      def update_template_detail(result)
        template_detail.customer_name = result.customer_name
        template_detail.family_member_count = result.family_member_count
        template_detail.save!
      end

      def transaction_form
        today = Time.now
        Form::BpjsKesehatan.new(template_detail.customer_number, nil, today.month, today.year)
      end

      def create_transaction
        action = Action::BpjsKesehatanTransaction::Create.new(transaction_form, template_detail.buyer_id, template_detail.phone_number, NORMAL_USER_TRANSACTION_TYPE)
        @transaction = action.run!
        @transaction.template_detail_id = @template_id
        @transaction.save!
        @transaction
      end

      def template_detail
        @template_detail ||= BpjsKesehatanRecurrenceTemplateDetail.find_by_id!(@template_id)
      end

      def postpaid_product
        'bpjs-kesehatan'
      end

      def generate_log_message
        {
          buyer_id: template_detail.buyer_id,
          template_detail_id: template_detail.id,
          customer_number: template_detail.customer_number
        }
      end
    end
  end
end
