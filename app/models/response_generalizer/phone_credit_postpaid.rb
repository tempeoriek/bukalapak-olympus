module ResponseGeneralizer
  class PhoneCreditPostpaid
    attr_accessor :customer_number, :customer_name
    attr_accessor :reference_no, :bill_count, :bill_period, :bill_amount
    attr_accessor :partner_admin_charge, :bukalapak_admin_charge, :admin_charge, :bukalapak_commission
    attr_accessor :total_amount, :provider_id, :provider_name, :provider_product_name
    attr_accessor :provider_logo_url, :partner, :status, :partner_transaction_id

    def initialize(&block)
      yield self if block_given?
    end
  end
end
