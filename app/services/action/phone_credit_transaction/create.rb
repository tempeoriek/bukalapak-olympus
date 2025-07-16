module Action
  module PhoneCreditTransaction
    class Create < Action::PostpaidTransaction::Create
      def initialize(form, buyer_id, transaction_type)
        super(form, buyer_id, transaction_type)
      end

      def run!
        inquiry = get_inquiry
        transaction = create_transaction(inquiry)
        save_transaction!(transaction)
      end

      private

      def create_transaction(inquiry)
        ::PhoneCreditPostpaidTransaction.new(
          buyer_id: @buyer_id,
          customer_name: inquiry.customer_name,
          phone_number: inquiry.customer_number,
          outstanding_bill: inquiry.bill_count,
          start_bill_period: inquiry.bill_period.min,
          end_bill_period: inquiry.bill_period.max,
          bill_amount: inquiry.bill_amount,
          partner_admin_charge: inquiry.partner_admin_charge,
          bukalapak_admin_charge: inquiry.bukalapak_admin_charge,
          bukalapak_commission: inquiry.bukalapak_commission,
          total_amount: inquiry.total_amount,
          provider_id: inquiry.provider_id,
          reference_number: inquiry.reference_no,
          partner: inquiry.partner,
          transaction_type: @transaction_type
        )
      end
    end
  end
end
