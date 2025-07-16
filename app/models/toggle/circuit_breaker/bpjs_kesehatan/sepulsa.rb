# frozen_string_literal: true

module Toggle
  module CircuitBreaker
    module BpjsKesehatan
      class Sepulsa < ::Toggle::Base
        def self.description
          '[REST-264] Toggle to enable circuit breaker on bpjs kesehatan on sepulsa partner'
        end
      end
    end
  end
end
