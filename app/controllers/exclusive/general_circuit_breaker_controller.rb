module Exclusive
  class GeneralCircuitBreakerController < ApplicationController
    include Response
    include Authenticate

    before_action :authorize!

    def show
      circuit_breaker = GeneralCircuitBreaker::CreditCardBill.instance
      render_response(serialize(circuit_breaker), 200)
    end

    private

    def authorize!
      raise ::Exceptions::UnauthorizedUser unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
    end

    def serialize(circuit_breaker)
      Serializer::Exclusive::GeneralCircuitBreaker.new(circuit_breaker)
    end
  end
end
