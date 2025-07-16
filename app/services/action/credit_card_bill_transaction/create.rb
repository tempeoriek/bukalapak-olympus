module Action
  module CreditCardBillTransaction
    class Create < Action::PostpaidTransaction::Create
      PARTNERS_WITHOUT_INQUIRY = %w[cimbniaga_thor]

      def initialize(form, buyer_id, transaction_type)
        super(form, buyer_id, transaction_type)
      end

      def run!
        inquiry = @form.partner.name.downcase.in?(PARTNERS_WITHOUT_INQUIRY) ? nil : get_inquiry
        transaction = create_transaction(inquiry)
        if @form.visa?
          # Based on the data from 2020-03-01 - 2020-05-31,
          # 95th percentile of created to paid time is around 2 hours
          # Reference: https://docs.google.com/spreadsheets/d/11GF93GbD7F3lJQycNEZlqe1QKohOlotkHpg5YzVuJVk/edit?ts=5ed8abeb#gid=2063294494
          # Remote trx registered on mothership will exp in 2 hours
          trx = save_transaction!(transaction, expiration_time_in_hour: 2)
        else
          trx = save_transaction!(transaction)
        end
        trx.set_card_number
        trx
      end

      private

      def create_transaction(inquiry)
        if @form.visa?
          token = inquiry.token
          response_code = inquiry.response_code
        end
        trx = ::CreditCardBillTransaction.new(
          buyer_id: @buyer_id,
          customer_number: @form.customer_number,
          customer_name: inquiry.nil? ? nil : inquiry.customer_name,
          statement_date: inquiry.nil? ? nil : inquiry.statement_date,
          due_date: inquiry.nil? ? nil : inquiry.due_date,
          amount: @form.amount.to_i + @form.biller.admin_charge,
          minimum_payment: inquiry.nil? ? nil : inquiry.minimum_payment,
          bukalapak_admin_charge: @form.biller.bukalapak_admin_charge,
          partner_admin_charge: @form.biller.partner_admin_charge,
          credit_card_biller_id: @form.biller_id,
          credit_card_bill_partner_id: @form.biller.partner.id,
          token: token, # visa only
          response_code: response_code, # visa only
          card_data: inquiry.nil? ? nil : inquiry.card_data,
          transaction_type: @transaction_type
        )
      end
    end
  end
end
