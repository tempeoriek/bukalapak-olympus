module Action
  module BpjsKesehatanTransaction
    class Create < Action::PostpaidTransaction::Create
      def initialize(form, buyer_id, phone_number, transaction_type)
        super(form, buyer_id, transaction_type)
        @phone_number = phone_number
      end

      def run!
        inquiry = get_inquiry
        transaction = create_transaction(inquiry)
        save_transaction!(transaction)
      end

      private

      def create_transaction(inquiry)
        month = Time.zone.now.month + inquiry.payment_period.to_i - 1
        year = Time.zone.now.year
        year = year + 1 if month > 12
        month = month - 12 if month > 12
        year = year.to_s
        month = '%02d' % month
        trx = ::BpjsKesehatanTransaction.new(
          buyer_id: @buyer_id,
          partner: inquiry.partner,
          customer_number: inquiry.customer_number,
          customer_name: inquiry.customer_name,
          family_member_count: inquiry.family_member_count,
          branch_name: inquiry.branch_name,
          amount: inquiry.amount,
          admin_charge: inquiry.admin_charge,
          bukalapak_admin_charge: inquiry.bukalapak_admin_charge,
          partner_admin_charge: inquiry.partner_admin_charge,
          payment_period: inquiry.payment_period,
          paid_until: year << '-' << month,
          phone_number: @phone_number,
          transaction_type: @transaction_type
        )

        inquiry.family_members&.each do |member|
          trx.bpjs_kesehatan_family_members.build(
            member_number: member[:member_number],
            name: member[:name],
            premium: member[:premium],
            balance: member[:balance]
          )
        end

        trx
      end
    end
  end
end
