module ResponseGeneralizer
  class CreditCardBill
    attr_accessor :customer_name, :customer_number, :statement_date,
      :due_date, :amount, :minimum_payment, :token, :card_data,
      :bukalapak_admin_charge, :partner_admin_charge, :state, :displayed_name,
      :biller, :credit_card_bill_partner_id, :reference_number,
      :partner_financial_journal_number, :partner, :partner_transaction_id,
      :partner_journal_number, :remote_transaction_id, :status, :response_code
    ATTR = %W[customer_name customer_number statement_date
      due_date amount minimum_payment token card_data
      bukalapak_admin_charge partner_admin_charge state displayed_name
      biller credit_card_bill_partner_id reference_number
      partner_financial_journal_number partner partner_transaction_id
      partner_journal_number remote_transaction_id status response_code]

    def initialize(&block)
      yield self if block_given?
    end

    def attributes
      result = {}
      ATTR.each do |key|
        value = self.send(key.to_sym)
        result[key.to_sym] = value unless value.nil?
      end
      result
    end
  end
end
