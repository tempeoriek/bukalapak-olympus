module Action::PdamAutoswitch::Mechanism
  class Result
    attr_accessor :last_timestamp, :total_count, :total_failed, :setting

    def initialize(last_timestamp:, total_count:, total_failed:, setting:)
      @last_timestamp = last_timestamp
      @total_count = total_count
      @total_failed = total_failed

      # The setting is the PdamAutoswitchGroupMemberSetting from the database.
      @setting = setting
    end

    def evaluate!
      return :noop unless active?
      return :allow if expired? or insufficent_count?
      return :block if processed_count_threshold_exceeded? or refund_rate_threshold_exceeded?

      :allow
    end

    def active?
      @setting && @setting.threshold_state == 'active'
    end

    # After the threshold period is expired, the total count and total failed
    # should be reset to 0.
    def expired?
      elapsed_seconds = (Time.now - @last_timestamp).seconds.ceil
      elapsed_seconds > @setting.threshold_period_in_seconds
    end

    # The total count is less than the minimum threshold, so no evaluation is
    # required.
    def insufficent_count?
      @total_count <= 0 or @total_count < @setting.threshold_min_trx
    end

    def processed_count_threshold_exceeded?
      @setting.threshold_type == 'processed_count' &&
        @total_count >= @setting.threshold_min_trx &&
        @total_failed >= @setting.threshold_value
    end

    def refund_rate_threshold_exceeded?
      @setting.threshold_type == 'refund_rate' &&
        @total_count >= @setting.threshold_min_trx &&
        @total_failed.to_f / @total_count.to_f * 100 >= @setting.threshold_value
    end
  end
end
