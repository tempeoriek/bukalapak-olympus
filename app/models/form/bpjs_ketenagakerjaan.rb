module Form
  class BpjsKetenagakerjaan < Base
    attr_accessor :customer_number, :payment_period, :bpjs_tk_type, :partner_object, :buyer_type

    BPJS_KETENAGAKERJAAN_PRODUCT_CODES = {
      12 => :pu,
      16 => :bpu
    }.freeze

    def initialize(customer_number, payment_period, buyer_type = NORMAL_BUYER_TYPE)
      @customer_number = customer_number
      @payment_period = payment_period.to_i
      @buyer_type = buyer_type
      set_bpjs_tk_type
      raise ::Exceptions::InvalidPaymentPeriod.new if invalid_payment_period?
      @partner_object = ::BpjsKetenagakerjaanPartner.find_by(state: 'active')
    end

    def invalid_payment_period?
      @payment_period && !@payment_period.between?(1,12)
    end

    def is_mitra?
      @buyer_type == AGENT_BUYER_TYPE || @buyer_type == COLLECTING_AGENT_BUYER_TYPE
    end

    private

    def set_bpjs_tk_type
      raise ::Exceptions::InvalidCustomerNumber.new unless @customer_number
      @bpjs_tk_type = BPJS_KETENAGAKERJAAN_PRODUCT_CODES[@customer_number.size]
      raise ::Exceptions::InvalidCustomerNumber.new unless @bpjs_tk_type
    end
  end
end
