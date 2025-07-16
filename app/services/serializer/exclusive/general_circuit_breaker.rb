module Serializer
  module Exclusive
    class GeneralCircuitBreaker
      def initialize(data)
        @data = data
      end

      def as_json(_options = {})
        [
          {
            name: Postpaid::Constant::CREDIT_CARD_BILL_PRODUCT,
            parameters: [
              {
                key: 'max_hourly_gmv',
                value: @data.total_gmv,
                threshold: @data.config[:max_hourly_gmv]
              },
              {
                key: 'max_hourly_trx',
                value: @data.total_trx,
                threshold: @data.config[:max_hourly_trx]
              }
            ],
            status: @data.allow? ? 'open' : 'closed'
          }
        ]
      end
    end
  end
end
