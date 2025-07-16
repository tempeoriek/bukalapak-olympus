# frozen_string_literal: true

module Config
  class GeneralCircuitBreaker < Base
    def self.description
      '[O2OVPE-483] Config for circuit breaker'
    end

    def self.config_name
      'postpaid/general-circuit-breaker'
    end
  end
end
