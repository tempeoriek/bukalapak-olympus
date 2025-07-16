module Action
  module ElectricityTransaction
    module Exclusive
      class DeductBalance

        def initialize(transaction)
          @transaction = transaction
          @amount = transaction.amount.to_i
        end

        def run!
          balance_amount = 0
          balance_threshold = 0

          ActiveRecord::Base.transaction do
            partner_balance = @transaction.partner_object.electricity_postpaid_partners_balances.find_by(type: balance_type)
            partner_balance.amount = partner_balance.amount.to_i - @amount.to_i
            balance_amount = partner_balance.amount
            balance_threshold = partner_balance.threshold
            partner_balance.save!
          end

          balance_metric_partner_key = "#{balance_metric_key.to_s}_#{@transaction.partner}".to_sym
          threshold_metric_partner_key = "#{threshold_metric_key.to_s}_#{@transaction.partner}".to_sym
          Observer.gauge(balance_metric_partner_key, balance_amount)
          Observer.gauge(threshold_metric_partner_key, balance_threshold)

          true
        rescue => e
          Honeybadger.notify(e)
          nil
        end

        def balance_metric_key
          {
            bukalapak: Observer::Metric::TAGLIS_BALANCE,
            mitra: Observer::Metric::TAGLIS_BALANCE_MITRA,
            bukaconnect: Observer::Metric::TAGLIS_BALANCE_BUKACONNECT
          }[balance_type.to_sym]
        end

        def threshold_metric_key
          {
            bukalapak: Observer::Metric::TAGLIS_THRESHOLD,
            mitra: Observer::Metric::TAGLIS_THRESHOLD_MITRA,
            bukaconnect: Observer::Metric::TAGLIS_THRESHOLD_BUKACONNECT
          }[balance_type.to_sym]
        end

        private

        def balance_type
          Postpaid::Constant::BALANCE_TYPE[@transaction.transaction_type.to_sym]
        end
      end
    end
  end
end
