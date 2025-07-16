module Action::PdamAutoswitch::Mechanism
  class Record
    include PostpaidTransactionUtility
    include Postpaid::Constant::Autoswitch

    # This lua scripts will record the pdam autoswitch usage.
    # The usage is recorded in a hash with the following fields:
    #  - last_timestamp: The last timestamp when the usage is recorded.
    #  - total_count: The total count of the usage.
    #  - total_failed: The total count of the failed usage.
    #
    # We use a single hash to record the usage for all the pdam autoswitch.
    # This reduces the number of keys in redis and allows us to fetch all the
    # usage in a single call.
    # The hash key is the member id, and the field key prefix is the member setting id.
    #
    # E.g.
    #
    # $ redis.hgetall('pdam_autoswitch:group_member:1')
    #
    # Output:
    # {
    #   'group_member_setting:1:processed_count:last_timestamp' => '2019-01-01 00:00:00',
    #   'group_member_setting:1:processed_count:total_count' => 100,
    #   'group_member_setting:1:processed_count:total_failed' => 10,
    #   'group_member_setting:2:refund_rate:last_timestamp' => '2019-01-01 00:00:00',
    #   'group_member_setting:2:refund_rate:total_count' => 100,
    #   'group_member_setting:2:refund_rate:total_failed' => 10
    # }
    #
    # The returned value is an array of the following:
    # [last_timestamp, total_count, total_failed]
    LUA_SCRIPT = <<~LUA
      local hash_key = KEYS[1]
      local field_key_prefix = KEYS[2]
      local now = tonumber(ARGV[1])
      local ttl = tonumber(ARGV[2])
      local err = tonumber(ARGV[3])

      local last_timestamp_field_key = field_key_prefix .. 'last_timestamp'
      local total_count_field_key = field_key_prefix .. 'total_count'
      local total_failed_field_key = field_key_prefix .. 'total_failed'

      -- Fetch the last_timestamp from redis.
      local last_timestamp = tonumber(redis.call('HGET', hash_key, last_timestamp_field_key)) or 0

      -- The last_timestamp is expired, reset the total_count and total_failed.
      if now - last_timestamp > ttl then
        redis.call('HMSET', hash_key, last_timestamp_field_key, now, total_count_field_key, 1, total_failed_field_key, err)
        redis.call('EXPIRE', hash_key, 86400)
      else
        -- The last_timestamp is not expired, increment the total_count and total_failed.
        -- The total_count is incremented by 1, and the total_failed is incremented only if there is an error.
        redis.call('HINCRBY', hash_key, total_count_field_key, 1)
        redis.call('HINCRBY', hash_key, total_failed_field_key, err)
      end

      return redis.call('HMGET', hash_key, last_timestamp_field_key, total_count_field_key, total_failed_field_key)
    LUA

    # Initialize the record mechanism.
    # E.g.
    # Action::PdamAutoswitch::Mechanism::Record.new(operator_id: 1, action: 'inquiry', status: :success).run!
    def initialize(operator_id:, action:, status:)
      @operator_id = operator_id
      @action = action
      @status = status

      @total_failed = 0
      @total_count = 0
    end

    def run!
      return unless Toggle::PdamAutoswitch.active?

      # Find all the active members for evaluation.
      members = PdamAutoswitchGroupMember
        .where(operator_id: @operator_id, state: 'active')
        .preload(:settings)

      # Evaluate each member.
      members.each do |member|
        next if member.settings.empty?

        # Evaluate each setting for the member.
        member.settings.each do |member_setting|
          next if member_setting.threshold_type != threshold_type

          state = record(member: member, member_setting: member_setting).evaluate!
          next unless state == :block

          # Find all the active members in the group, sorted by priority.
          # If there is only 1 active member, then there is no need to switch.
          group_members = PdamAutoswitchGroupMember
            .where(autoswitch_group_id: member.autoswitch_group_id)
            .where.not(state: 'deleted')
            .order(id: :asc)
            .to_a
          return :unavailable if group_members.size <= 1

          # Run in transaction so that the state is rolled back if there is an error.

          ApplicationRecord.transaction do
            # Deactivate the member.
            member.update!(state: 'inactive')

            # Switch to the next active member.
            #
            # E.g.
            # group_members = [A, B, C, D]
            #
            # If starting from A, then switch to B.
            # If starting from B, then switch to C.
            # If starting from C, then switch to D.
            # If starting from D, then switch to A.
            # If starting from A, but B is deleted, then switch to C.
            # If starting from A, but all the members are deleted, then switch back to A.
            curr_pos = group_members.find_index{|m| m.id == member.id}
            next_pos = (curr_pos+1) % group_members.size

            if curr_pos == 0
              set_switchback(member.autoswitch_group_id)
            end

            # Clear current partner key in Redis after switching.
            clear(member)

            next_member = group_members[next_pos]
            next_member.state = 'active'
            next_member.save!

            publish_metric(member, next_member)
            publish_log(member, next_member, member_setting)
          end

          return :switched
        end
      end

      :noop
    end

    private

    def clear(member)
      RedisOlympus.del(hash_key(member.id))
    end

    def record(member:, member_setting:)
      now = Time.now.to_i
      ttl = member_setting.threshold_period_in_seconds.to_i
      err = @status == :failed ? 1 : 0

      keys = [hash_key(member.id), field_key_prefix(member_setting.id, member_setting.threshold_type)]
      argv = [now, ttl, err]

      resp = RedisOlympus.eval(LUA_SCRIPT, keys: keys, argv: argv)

      @total_count = resp[1].to_i
      @total_failed = resp[2].to_i

      Result.new(last_timestamp: Time.at(resp[0].to_i).to_datetime,
                 total_count: @total_count,
                 total_failed: @total_failed,
                 setting: member_setting)
    end

    # The hash key is the member id.
    # E.g.
    # pdam_autoswitch:group_member:1
    def hash_key(id)
      "#{AUTOSWITCH_PDAM_KEY}:#{id}"
    end

    # The field key prefix is the member setting id.
    # The threshold type is either 'processed_count' or 'refund_rate'.
    # E.g.
    # group_member_setting:1:processed_count
    def field_key_prefix(id, threshold_type)
      "group_member_setting:#{id}:#{threshold_type}:"
    end

    def threshold_type
      if @action == 'inquiry'
        'processed_count'
      else
        'refund_rate'
      end
    end

    def set_switchback(group_id)
      RedisOlympus.set("#{SWITCHBACK_PDAM_KEY}:#{group_id}", true, ex: PARTNER_SWITCHBACK_DURATION, nx: true)
    end

    def publish_metric(old_partner, new_partner)
      tags = {
        autoswitch_group_id: old_partner.autoswitch_group_id,
        new_partner: new_partner.operator.name,
        old_partner: old_partner.operator.name,
        threshold_type: threshold_type
      }
      Observer.counter(
        Observer::Metric::PDAM_AUTO_SWITCH, 1, tags
      )
    end

    def publish_log(old_partner, new_partner, threshold)
      tags = [PDAM_PRODUCT, 'autoswitch', 'partner_switch']
      info = {
        autoswitch_group_id: old_partner.autoswitch_group_id,
        total_count: @total_count,
        total_failed: @total_failed,
        total_failed_in_percentage: "#{(@total_failed.to_f / @total_count * 100).round(2)}%",
        threshold: threshold_type == 'refund_rate' ? "#{threshold.threshold_value}%" : threshold.threshold_value,
        min_total_count: threshold.threshold_min_trx
      }
      log_error(tags, "Partner switched from #{old_partner.operator.name} to #{new_partner.operator.name} by #{threshold_type}", nil, info)
    end
  end
end
