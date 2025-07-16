module Action
  module PdamTransaction
    class Create < Action::PostpaidTransaction::Create
      include PostpaidTransactionUtility

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
        params = {
          buyer_id: @buyer_id,
          partner: inquiry.partner,
          customer_number: inquiry.customer_number,
          customer_name: inquiry.customer_name,
          start_bill_period: inquiry.start_bill_period,
          end_bill_period: inquiry.end_bill_period,
          amount: inquiry.amount,
          pdam_operator_id: inquiry.operator&.[](:id),
          penalty_fee: inquiry.penalty_fee,
          bukalapak_admin_charge: inquiry.bukalapak_admin_charge,
          partner_admin_charge: inquiry.partner_admin_charge,
          address: inquiry.address,
          transaction_type: @transaction_type,
          stand_meter: inquiry.stand_meter,
          segel: inquiry.segel,
          retribution: inquiry.retribution,
          details: inquiry.details || {}
        }

        bills = inquiry&.bills

        trx = ::PdamTransaction.new(params)

        bills&.each do |bill|
          trx.pdam_bills.build(
            bill_period: bill[:bill_period],
            penalty_fee: bill[:penalty_fee],
            amount: bill[:amount],
            cubication: bill[:cubication],
            tariff: bill[:tariff],
            usage: bill[:usage]
          )
        end

        trx
      end
    end
  end
end
