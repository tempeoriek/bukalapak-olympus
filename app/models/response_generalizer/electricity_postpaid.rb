module ResponseGeneralizer
  class ElectricityPostpaid
    include CachePartnerResponseUtility
    include MiddlemanResponseMapperUtility

    attr_accessor :customer_number, :customer_name, :segmentation, :power
    attr_accessor :stand_meter, :outstanding_bill, :unpaid_bill, :penalty_fee
    attr_accessor :admin_charge, :amount, :info_text, :period, :partner_transaction_id
    attr_accessor :reference_number, :partner, :bills, :partner_object, :status
    attr_accessor :remaining_billing_sheet, :message

    def initialize(response, partner_object, &block)
      @response = response
      @partner_object = partner_object
      yield self if block_given?
    end

    def admin_charge
      @admin_charge = bukalapak_admin_charge + partner_admin_charge
    end

    def period
      @period ||= month_summary
    end

    def partner_transaction_id
      @partner_transaction_id ||= @response[:partner_transaction_id]
    end

    def partner
      @partner = @partner_object.name
    end

    def bukalapak_admin_charge
      @bills ? @bills.length * @partner_object.bukalapak_admin_charge : 0
    end

    def partner_admin_charge
      @bills ? @bills.length * @partner_object.partner_admin_charge : 0
    end

    def month_summary
      @bills.map{ |bill| bill[:bill_period] }
    end

    def bukalapak_commission
      @bills ? @bills.length * @partner_object.bukalapak_commission : @partner_object.bukalapak_commission
    end

    def customer_number
      @customer_number ||= @response[:customer_number]&.strip
    end

    def response_code
      retrieve_middleman_response_code(product_type, partner, partner_response_code)
    end

    def failed_reason
      retrieve_middleman_failed_reason(partner, partner_response_code)
    end

    def remaining_billing_sheet
      @remaining_billing_sheet ||= @response[:remaining_billing_sheet].to_i
    end

    def message
      @message ||= @response[:message].to_i
    end

    private

    def partner_response_code
      action = "inquiry"
      retrieve_partner_response(product_type, action, partner, customer_number)
    end

    def product_type
      product_type = self.class.name.split('::').last.underscore
    end
  end
end
