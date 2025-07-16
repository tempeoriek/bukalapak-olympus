module Recurrence
  module PhoneCreditPostpaid
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
        template_detail.save!
      end

      def transaction_form
        Form::PhoneCredit.new(template_detail.phone_number, nil, RECURRENCE_ELIGIBLE_BUYER_TYPE)
      end

      def create_transaction
        action = Action::PhoneCreditTransaction::Create.new(transaction_form, template_detail.buyer_id, NORMAL_USER_TRANSACTION_TYPE)
        @transaction = action.run!
        @transaction.template_detail_id = @template_id
        @transaction.save!
        @transaction
      end

      def template_detail
        @template_detail ||= PhoneCreditPostpaidRecurrenceTemplateDetail.find_by_id!(@template_id)
      end

      def postpaid_product
        'phone-credit-postpaid'
      end

      def generate_log_message
        {
          buyer_id: template_detail.buyer_id,
          template_detail_id: template_detail.id,
          customer_number: template_detail.phone_number
        }
      end
    end
  end
end
