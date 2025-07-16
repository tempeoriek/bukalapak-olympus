module Form
  class Base
    include Postpaid::Constant

    def customer_number
      raise NoMethodError
    end

    def payment_period
      raise NoMethodError
    end

    def operator_id
      raise NoMethodError
    end

    def operator
      raise NoMethodError
    end
  end
end
