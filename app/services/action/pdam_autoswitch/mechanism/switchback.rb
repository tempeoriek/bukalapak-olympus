# frozen_string_literal: true

module Action::PdamAutoswitch::Mechanism
    class Switchback
        include PostpaidTransactionUtility
        include Postpaid::Constant::Autoswitch

        def perform
            switched_count = 0
            # Search and evaluate all autoswitch groups
            PdamAutoswitchGroup.all.each do |group|
                # Abort if the switchback key exists, meaning the switchback countdown has not yet run out
                key_exists = RedisOlympus.exists?("#{SWITCHBACK_PDAM_KEY}:#{group.id}")
                next if key_exists

                # Get highest priority member
                highest_priority_member = group.members.where.not(state: 'deleted').order(id: :asc).first

                # Get current partner
                current_member = group.members.where(state: 'active').first

                # Do nothing if current member already highest priority member
                next if highest_priority_member.nil? || current_member.nil?
                next if highest_priority_member.id == current_member.id

                # Switch to highest priority partner
                ApplicationRecord.transaction do
                    current_member.update!(state: 'inactive')
                    highest_priority_member.update!(state: 'active')

                    # Clear current member key in Redis after switching.
                    clear(current_member.id)
                end

                publish_metric(current_member, highest_priority_member)
                publish_log(current_member, highest_priority_member, group.id)
                switched_count += 1
            end

            switched_count
        end

        private

        def clear(id)
            RedisOlympus.del("#{AUTOSWITCH_PDAM_KEY}:#{id}")
        end

        def publish_metric(old_member, new_member)
            tags = {
                new_member: new_member.id,
                old_member: old_member.id,
                threshold_type: 'switchback'
            }
            Observer.counter(
                Observer::Metric::PDAM_AUTO_SWITCH , 1, tags
            )
        end

        def publish_log(old_member, new_member, group_id)
            tags = [PDAM_PRODUCT, 'autoswitch', 'partner_switch', 'switchback']
            info = {
                switchback_duration: PARTNER_SWITCHBACK_DURATION,
            }
            log_request(tags, "PDAM partner on group #{group_id} switched from #{old_member.id} to #{new_member.id} by switchback", nil, info)
        end
    end
end
  