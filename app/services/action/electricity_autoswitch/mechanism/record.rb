# frozen_string_literal: true

module Action
  module ElectricityAutoswitch
    module Mechanism
      class Record
        include PostpaidTransactionUtility
        include Postpaid::Constant::Autoswitch

        # This lua scripts will record the electricity autoswitch usage.
        # The usage is recorded in a hash with the following fields:
        #  - last_timestamp: The last timestamp when the usage is recorded.
        #  - total_count: The total count of the usage.
        #  - total_failed: The total count of the failed usage.
        #
        # We use a single hash to record the usage for all the electricity autoswitch.
        # This reduces the number of keys in redis and allows us to fetch all the
        # usage in a single call.
        # The hash key is the member id, and the field key prefix is the member setting id.
        #
        # E.g.
        #
        # $ redis.hgetall('electricity_autoswitch:partner:1')
        #
        # Output:
        # {
        #   'threshold:processed_count:last_timestamp' => '2019-01-01 00:00:00',
        #   'threshold:processed_count:total_count' => 100,
        #   'threshold:processed_count:total_failed' => 10,
        #   'threshold:refund_rate:last_timestamp' => '2019-01-01 00:00:00',
        #   'threshold:refund_rate:total_count' => 100,
        #   'threshold:refund_rate:total_failed' => 10
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

          local last_timestamp_field_key = field_key_prefix .. ':last_timestamp'
          local total_count_field_key = field_key_prefix .. ':total_count'
          local total_failed_field_key = field_key_prefix .. ':total_failed'

          -- Fetch the last_timestamp from redis.
          local last_timestamp = tonumber(redis.call('HGET', hash_key, last_timestamp_field_key)) or 0

          -- The last_timestamp is expired, reset the total_count and total_failed.
          if now - last_timestamp > ttl then
            redis.call('HMSET', hash_key, last_timestamp_field_key, now, total_count_field_key, 1, total_failed_field_key, err)
            redis.call('EXPIRE', hash_key, 86400)
          else
            -- The last_timestamp is not expired, increment the total_count and total_failed.
            -- The total_failed is incremented only if there is an error.
            redis.call('HINCRBY', hash_key, total_failed_field_key, err)
            redis.call('HINCRBY', hash_key, total_count_field_key, 1)
          end

          return redis.call('HMGET', hash_key, last_timestamp_field_key, total_count_field_key, total_failed_field_key)
        LUA

        # Initialize the record mechanism.
        # E.g.
        # Action::ElectricityAutoswitch::Mechanism::Record.new(action: 'inquiry', status: :success).run!
        def initialize(action:, status:)
          @action = action
          @status = status

          @total_failed = 0
          @total_count = 0
        end

        def run!
          return unless Toggle::ElectricityPostpaidAutoswitch.active?

          # Find all partner configs for evaluation.
          partner_configs = Config::ElectricityPostpaidAutoswitch.config(config: []).fetch(:config, [])
          return :noop if partner_configs.empty?

          # Evaluate each partner config.
          partner_configs.each do |config|
            next if config[:status] != 'active'

            # Evaluate partner by status
            partner = ElectricityPostpaidPartner.find_by(name: config[:partner_name], state: 'active')
            next if partner.blank?

            # Evaluate each threshold setting for the partner config.
            config[:thresholds].each do |threshold|
              next if threshold[:type] != threshold_type || threshold[:status] != 'active'

              state = record(partner: partner, threshold: threshold).evaluate!
              next unless state == :block

              # Find all the active partners in the config, sorted by priority.
              # If there is only 1 active partner, then there is no need to switch.
              order_by_priority = partner_configs.map do |config|
                "WHEN name = '#{config[:partner_name]}' THEN #{config[:priority]}"
              end.join(' ')

              partners = ElectricityPostpaidPartner
                        .where(name: partner_configs.map { |config| config[:partner_name] })
                        .order(Arel.sql("CASE #{order_by_priority} END"))
                        .to_a

              return :unavailable if partners.size <= 1

              # Run in transaction so that the state is rolled back if there is an error.
              next_partner = nil
              ApplicationRecord.transaction do
                # Deactivate the partner.
                partner.update!(state: 'inactive')

                # Switch to the next active member.
                #
                # E.g.
                # partner_configs = [A, B, C, D]
                #
                # If starting from A, then switch to B.
                # If starting from B, then switch to C.
                # If starting from C, then switch to D.
                # If starting from D, then switch to A.
                # If starting from A, but B is deleted, then switch to C.
                # If starting from A, but all the members are deleted, then switch back to A.
                curr_pos = partners.find_index { |p| p.id == partner.id }
                next_pos = (curr_pos + 1) % partners.size

                next_partner = partners[next_pos]
                next_partner.state = 'active'
                next_partner.save!
              end

              publish_metric(partner, next_partner)
              publish_log(partner, next_partner, threshold)

              # Clear current partner key in Redis after switching
              clear(partner: partner)

              # Start switchback countdown if next partner is not first priority partner
              start_switchback_countdown unless next_partner.id == partners[0].id

              return :switched
            end
          end

          :noop
        end

        private

        def record(partner:, threshold:)
          now = Time.now.to_i
          ttl = threshold[:period_in_seconds].to_i
          err = @status == :failed ? 1 : 0

          keys = [hash_key(partner.id), field_key_prefix(threshold[:type])]
          argv = [now, ttl, err]

          resp = RedisOlympus.eval(LUA_SCRIPT, keys: keys, argv: argv)

          @total_count = resp[1].to_i
          @total_failed = resp[2].to_i

          Result.new(last_timestamp: Time.at(resp[0].to_i).to_datetime,
                     total_count: @total_count,
                     total_failed: @total_failed,
                     threshold: threshold)
        end

        def clear(partner:)
          RedisOlympus.del(hash_key(partner.id))
        end
        
        def start_switchback_countdown
          RedisOlympus.set(SWITCHBACK_ELECTRICITY_KEY, Time.now, ex: PARTNER_SWITCHBACK_DURATION, nx: true)
        end

        # The hash key is the partner id.
        # E.g.
        # electricity_autoswitch:partner:1
        def hash_key(id)
          "#{AUTOSWITCH_ELECTRICITY_KEY}:#{id}"
        end

        # Id is partner id.
        # The threshold type is either 'processed_count' or 'refund_rate'.
        # E.g.
        # threshold:1:processed_count
        def field_key_prefix(threshold_type)
          "threshold:#{threshold_type}"
        end

        def threshold_type
          if @action == 'inquiry'
            'processed_count'
          else
            'refund_rate'
          end
        end

        def publish_metric(old_partner, new_partner)
          tags = {
            new_partner: new_partner.name,
            old_partner: old_partner.name,
            threshold_type: threshold_type
          }
          Observer.counter(
            Observer::Metric::TAGLIS_AUTO_SWITCH, 1, tags
          )
        end

        def publish_log(old_partner, new_partner, threshold)
          tags = [ELECTRICITY_PRODUCT, 'autoswitch', 'partner_switch']
          info = {
            total_count: @total_count,
            total_failed: @total_failed,
            total_failed_in_percentage: "#{(@total_failed.to_f / @total_count * 100).round(2)}%",
            threshold: threshold_type == 'refund_rate' ? "#{threshold[:value]}%" : threshold[:value],
            min_total_count: threshold[:min_trx]
          }
          log_error(tags, "Partner switched from #{old_partner.name} to #{new_partner.name} by #{threshold_type}", nil, info)
        end
      end
    end
  end
end
