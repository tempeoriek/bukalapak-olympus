# frozen_string_literal: true

module Config
  class AutoswitchSwitchbackDuration < Base
    def self.description
      '[O2OVPE-2703] Autoswitch Switchback Duration'
    end

    def self.config_name
      'olympus/config/autoswitch-switchback-duration'
    end

    def self.get_duration_by_day(default)
      cfg = config({})
    
      current_day = Time.now.wday # 0: Sunday, 6: Saturday
      day_category = if current_day == 0 || current_day == 6
                       :weekend
                     else
                       :weekday
                     end
    
      duration = cfg[day_category].to_i
      duration = duration != 0 ? duration.minutes : default.minutes

      duration
    end
  end
end
