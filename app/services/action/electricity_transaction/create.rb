module Action
  module ElectricityTransaction
    class Create < Action::PostpaidTransaction::Create
      include PostpaidTransactionUtility

      def initialize(form, buyer_id, transaction_type, context = nil)
        super(form, buyer_id, transaction_type, context)
      end

      def run!
        inquiry = get_inquiry
        transaction = create_transaction(inquiry)
        save_transaction!(transaction)
      end

      private

      def create_transaction(inquiry)
        trx = ::PostpaidTransaction.new(
          buyer_id: @buyer_id,
          customer_number: inquiry.customer_number,
          customer_name: inquiry.customer_name,
          segmentation: inquiry.segmentation,
          power: inquiry.power,
          stand_meter: inquiry.stand_meter,
          outstanding_bill: inquiry.outstanding_bill,
          unpaid_bill: inquiry.unpaid_bill,
          penalty_fee: inquiry.penalty_fee,
          bukalapak_admin_charge: inquiry.bukalapak_admin_charge,
          partner_admin_charge: inquiry.partner_admin_charge,
          bukalapak_commission: inquiry.bukalapak_commission,
          admin_charge: inquiry.admin_charge,
          amount: inquiry.amount,
          reference_number: inquiry.reference_number,
          partner: inquiry.partner,
          transaction_type: @transaction_type,
          created_on_platform: @context&.client&.platform,
          created_on_version: @context&.client&.version
        )

        inquiry.bills&.each do |bill|
          trx.bills.build(
            bill_period: bill[:bill_period]&.to_date,
            due_date: bill[:due_date]&.to_date,
            penalty_fee: bill[:penalty_fee],
            amount: bill[:amount],
            previous_meter: bill[:previous_meter],
            current_meter: bill[:current_meter]
          )
        end

        if @form.mass_bill_id.present?
          trx.build_electricity_postpaid_mass_bill(mass_bill_id: @form.mass_bill_id)
        end

        trx
      end
    end
  end
end
