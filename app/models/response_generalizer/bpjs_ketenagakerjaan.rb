module ResponseGeneralizer
  class BpjsKetenagakerjaan
    attr_accessor :customer_number, :customer_name, :bpjs_tk_type
    attr_accessor :partner, :amount, :bukalapak_admin_charge, :partner_admin_charge
    attr_accessor :payment_period, :start_bill_period, :end_bill_period, :branch_name, :bill_code
    attr_accessor :bills, :status, :reference_number, :npp, :division, :partner_transaction_id, :info
    attr_accessor :unpaid_bills_text, :unpaid_bills

    def initialize
      yield self if block_given?
    end

    def admin_charge
      bukalapak_admin_charge + partner_admin_charge
    end
  end
end
