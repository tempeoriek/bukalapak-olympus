# frozen_string_literal: true

module Action
  module ElectricityAutoswitch
    module Mechanism
      class Switchback
        include PostpaidTransactionUtility
        include Postpaid::Constant::Autoswitch

        @current_partner = nil
        @highest_priority_partner = nil

        def perform
          # Abort if the switchback key exists, meaning the switchback countdown has not yet run out
          return :noop if RedisOlympus.exists?(SWITCHBACK_ELECTRICITY_KEY)

          # Abort if no need to switch
          return :noop unless should_switch_partner?

          # Switch to highest priority partner
          ApplicationRecord.transaction do
            @current_partner.update!(state: 'inactive')
            @highest_priority_partner.update!(state: 'active')
          end

          # Clear current partner key in Redis after switching
          clear(partner: @current_partner)

          publish_metric(@current_partner, @highest_priority_partner)
          publish_log(@current_partner, @highest_priority_partner)

          :switched
        end

        private

        def should_switch_partner?
          # Get autoswitch partner configs
          partner_configs = Config::ElectricityPostpaidAutoswitch.config(config: []).fetch(:config, [])
          return false if partner_configs.empty?

          # Get highest priority partner config with active status
          highest_priority_partner_config = partner_configs.select { |config| config[:status] == "active" }.min_by { |config| config[:priority] }
          return false if highest_priority_partner_config.nil?

          # Get highest priority partner
          @highest_priority_partner = ElectricityPostpaidPartner.find_by(name: highest_priority_partner_config[:partner_name])
          return false if @highest_priority_partner.nil?

          # Check if the current partner is already the highest priority partner
          @current_partner = ElectricityPostpaidPartner.find_by(state: 'active')
          return false if @current_partner.nil? || @current_partner.name == @highest_priority_partner.name

          true
        end

        def clear(partner:)
          RedisOlympus.del("#{AUTOSWITCH_ELECTRICITY_KEY}:#{partner.id}")
        end

        def publish_metric(old_partner, new_partner)
          tags = {
            new_partner: new_partner.name,
            old_partner: old_partner.name,
            threshold_type: 'switchback'
          }
          Observer.counter(
            Observer::Metric::TAGLIS_AUTO_SWITCH, 1, tags
          )
        end

        def publish_log(old_partner, new_partner)
          tags = [ELECTRICITY_PRODUCT, 'autoswitch', 'partner_switch', 'switchback']
          info = {
            switchback_duration: PARTNER_SWITCHBACK_DURATION,
          }
          log_request(tags, "Partner switched from #{old_partner.name} to #{new_partner.name} by switchback", nil, info)
        end
      end
    end
  end
end
