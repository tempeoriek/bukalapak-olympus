# frozen_string_literal: true

module Toggle
  module CircuitBreaker
    module ElectricityPostpaid
      class Ayoconnect < ::Toggle::Base
        def self.description
          '[REST-265] Toggle to enable circuit breaker on electricity postpaid product for ayoconnect partner'
        end
      end
    end
  end
end
