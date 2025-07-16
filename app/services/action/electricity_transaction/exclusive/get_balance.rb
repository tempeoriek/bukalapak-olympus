module Action
  module ElectricityTransaction
    module Exclusive
      class GetBalance
        include Postpaid::Constant

        def run!
          %w[bukalapak mitra].map do |type|
            build_response(type)
          end
        end

        private

        def build_response(type)
          balance = ::Keystore.get(balance_key(type))
          threshold = ::Keystore.get(threshold_key(type))

          raise ::Exceptions::RecordNotSetError.new('balance') if balance.nil?
          raise ::Exceptions::RecordNotSetError.new('threshold') if threshold.nil?

          {
            balance: balance.to_i,
            threshold: threshold.to_i,
            type: type
          }
        end

        def balance_key(type)
          "Postpaid::Constant::BalanceTracker::ElectricityPostpaid::#{type.upcase}_BALANCE".constantize
        end

        def threshold_key(type)
          "Postpaid::Constant::BalanceTracker::ElectricityPostpaid::#{type.upcase}_THRESHOLD".constantize
        end
      end
    end
  end
end
