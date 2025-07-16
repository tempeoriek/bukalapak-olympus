module Form
  class BpjsKesehatan < Base
    attr_accessor :customer_number, :payment_period, :month, :year, :partner_object, :buyer_type

    def initialize(customer_number, payment_period, month = 0, year = 0, buyer_type = NORMAL_BUYER_TYPE)
      @customer_number = customer_number
      @buyer_type = buyer_type
      if payment_period.present?
        @payment_period = payment_period
        set_month_and_year
      else
        @month = month.to_i
        @year = year.to_i
        set_payment_period
      end
      @partner_object = ::BpjsKesehatanPartner.find_by(state: 'active')
      raise ::Exceptions::InvalidPaymentPeriod.new if invalid_payment_period?
    end

    def payment_period
      @payment_period
    end

    def month
      @month
    end

    def year
      @year
    end

    # aussme @payment_period is set
    def set_month_and_year
      today = Time.now
      paid_until = today + @payment_period.to_i.month
      @month = paid_until.month
      @year = paid_until.year
    end

    def set_payment_period
      raise ::Exceptions::InvalidPaymentPeriod.new unless @month.between?(1, 12)
      today = Time.now
      period = (((@year -today.year)*12) + @month) - today.month + 1
      @payment_period = '%02i' % period
    end

    def invalid_payment_period?
      @payment_period && !@payment_period.to_i.between?(1, 12)
    end

    def is_mitra?
      @buyer_type == AGENT_BUYER_TYPE || @buyer_type == COLLECTING_AGENT_BUYER_TYPE
    end
  end
end
