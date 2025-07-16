# frozen_string_literal: true

module Action
  module ElectricityAutoswitch
    module Mechanism
      class Result
        attr_accessor :last_timestamp, :total_count, :total_failed, :threshold

        def initialize(last_timestamp:, total_count:, total_failed:, threshold:)
          @last_timestamp = last_timestamp
          @total_count = total_count
          @total_failed = total_failed

          # The threshold is the threshold setting from the config.
          @threshold = threshold
        end

        def evaluate!
          return :noop unless active?
          return :allow if expired? || insufficent_count?
          return :block if processed_count_threshold_exceeded? || refund_rate_threshold_exceeded?

          :allow
        end

        def active?
          @threshold && @threshold[:status] == 'active'
        end

        # After the threshold period is expired, the total count and total failed
        # should be reset to 0.
        def expired?
          elapsed_seconds = (Time.now - @last_timestamp).seconds.ceil
          elapsed_seconds > @threshold[:period_in_seconds]
        end

        # The total count is less than the minimum threshold, so no evaluation is
        # required.
        def insufficent_count?
          @total_count <= 0 or @total_count < @threshold[:min_trx]
        end

        def processed_count_threshold_exceeded?
          @threshold[:type] == 'processed_count' &&
            @total_count >= @threshold[:min_trx] &&
            @total_failed >= @threshold[:value]
        end

        def refund_rate_threshold_exceeded?
          @threshold[:type] == 'refund_rate' &&
            @total_count >= @threshold[:min_trx] &&
            @total_failed.to_f / @total_count.to_f * 100 >= @threshold[:value]
        end
      end
    end
  end
end
