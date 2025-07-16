# frozen_string_literal: true

module Config
  class ElectricityPostpaidAutoswitch < Base
    def self.description
      '[O2OVPE-1674] Electricity Postpaid Autoswitch'
    end

    def self.config_name
      'olympus/config/electricity-postpaid-autoswitch'
    end
  end
end
