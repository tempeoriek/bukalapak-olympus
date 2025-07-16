module ResponseGeneralizer
  class BpjsKesehatan
    attr_accessor :customer_number, :customer_name
    attr_accessor :partner, :amount, :bukalapak_admin_charge, :partner_admin_charge
    attr_accessor :family_member_count, :payment_period, :branch_name, :paid_until
    attr_accessor :family_members, :partner_transaction_id, :status, :reference_number, :info

    def initialize(&block)
      yield self if block_given?
    end

    def admin_charge
      bukalapak_admin_charge + partner_admin_charge
    end
  end
end
