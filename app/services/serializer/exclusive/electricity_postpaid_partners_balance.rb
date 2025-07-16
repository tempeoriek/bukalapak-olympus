module Serializer
  module Exclusive
    class ElectricityPostpaidPartnersBalance
      attr_reader :balance

      def initialize(balance)
        @balance = balance
      end

      def as_json(_options = {})
        {
          amount: balance.amount,
          threshold: balance.threshold,
          type: balance.type
        }
      end
    end
  end
end
