module Action
  module ElectricityTransaction
    module Exclusive
      class UpdateBalance
        include Postpaid::Constant

        def initialize(form)
          @form = form
          @balance = form.balance.to_i
          @threshold = form.threshold.to_i
          @type = form.type
        end

        def run!
          ::Keystore.set(balance_key, @balance)
          ::Keystore.set(threshold_key, @threshold)

          Observer.gauge(balance_metric_key, @balance)
          Observer.gauge(threshold_metric_key, @threshold)

          {
            balance: @balance,
            threshold: @threshold,
            type: @type
          }
        end

        private

        def balance_key
          return BalanceTracker::ElectricityPostpaid::MITRA_BALANCE if @form.mitra?
          BalanceTracker::ElectricityPostpaid::BUKALAPAK_BALANCE
        end

        def threshold_key
          return BalanceTracker::ElectricityPostpaid::MITRA_THRESHOLD if @form.mitra?
          BalanceTracker::ElectricityPostpaid::BUKALAPAK_THRESHOLD
        end

        def balance_metric_key
          return Observer::Metric::TAGLIS_BALANCE_MITRA if @form.mitra?
          Observer::Metric::TAGLIS_BALANCE
        end

        def threshold_metric_key
          return Observer::Metric::TAGLIS_THRESHOLD_MITRA if @form.mitra?
          Observer::Metric::TAGLIS_THRESHOLD
        end
      end
    end
  end
end
