# frozen_string_literal: true

module Toggle
  module CircuitBreaker
    module ElectricityPostpaid
      class Tektaya < ::Toggle::Base
        def self.description
          '[REST-686] Toggle to enable circuit breaker on electricity postpaid product for tektaya partner'
        end
      end
    end
  end
end
