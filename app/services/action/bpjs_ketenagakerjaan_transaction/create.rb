module Action
  module BpjsKetenagakerjaanTransaction
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
        trx = ::BpjsKetenagakerjaanTransaction.new(
          buyer_id: @buyer_id,
          partner: inquiry.partner,
          customer_number: inquiry.customer_number,
          customer_name: inquiry.customer_name,
          branch_name: inquiry.branch_name,
          admin_charge: inquiry.admin_charge,
          payment_period: inquiry.payment_period,
          start_bill_period: inquiry.start_bill_period,
          end_bill_period: inquiry.end_bill_period,
          amount: inquiry.amount,
          transaction_type: @transaction_type,
          bukalapak_admin_charge: inquiry.bukalapak_admin_charge,
          partner_admin_charge: inquiry.partner_admin_charge,
          bpjs_tk_type: inquiry.bpjs_tk_type,
          division: inquiry.division,
          npp: inquiry.npp,
          bill_code: inquiry.bill_code
        )

        trx.unpaid_bills = true if inquiry.unpaid_bills

        inquiry.bills&.each do |bill|
          trx.bpjs_ketenagakerjaan_bills.build(
            jht: bill[:jht],
            jkk: bill[:jkk],
            jkm: bill[:jkm],
            jkp: bill[:jkp],
            jp: bill[:jp],
            amount: bill[:amount]
          )
        end

        trx
      end
    end
  end
end
