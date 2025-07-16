# frozen_string_literal: true

module GeneralCircuitBreaker
  class Base
    def initialize(product_type)
      @product_type = product_type
    end

    def incr(gmv)
      incr_with_ttl(:gmv, gmv)
      incr_with_ttl(:trx, 1)
      true
    rescue Redis::BaseError => e
      # do nothing when redis fails
      LogBook.error(e.message, %W[general_circuit_breaker increment #{@product_type}], nil)
      false
    end

    def allow?()
      total_gmv < config[:max_hourly_gmv] && total_trx < config[:max_hourly_trx]
    rescue Redis::BaseError => e
      # Allow transactions to be created if redis failed.
      LogBook.error(e.message, %W[general_circuit_breaker allow #{@product_type}], nil)
      true
    end

    def total_gmv
      total(:gmv)
    end

    def total_trx
      total(:trx)
    end

    def config
      # Set an unreasonably high value.
      {
        max_hourly_gmv: 1_000_000_000,
        max_hourly_trx: 100_000,
      }
    end

    private

    def incr_with_ttl(type, val)
      hour = Time.now.beginning_of_hour.in_time_zone('Asia/Jakarta')

      key = build_key(type)
      total = RedisOlympus.incrby(key, val).to_i
      RedisOlympus.expireat(key, (hour + 1.hour + 10.second).to_i) if total == val

      opts = {
        metric_type: type.to_s,
        product_type: @product_type
      }
      Observer.counter(Observer::Metric::GENERAL_CIRCUIT_BREAKER, val, opts)

      total
    end

    def total(type)
      key = build_key(type)

      RedisOlympus.get(key).to_i
    end

    def build_key(type)
      hour = Time.now.beginning_of_hour.in_time_zone('Asia/Jakarta')
      "#{@product_type}-hourly-#{type}:#{hour.strftime('%Y-%m-%d-%H:%M')}"
    end
  end

  class CreditCardBill < Base
    include Singleton

    CONFIG = {
      max_hourly_gmv: 208_836_000,
      max_hourly_trx: 72
    }.freeze

    def initialize
      super(Postpaid::Constant::CREDIT_CARD_BILL_PRODUCT)
    end

    def config
      Config::GeneralCircuitBreaker.config(credit_card_bill: CONFIG).fetch(:credit_card_bill, CONFIG)
    end
  end
end
