# frozen_string_literal: true

module CircuitBreaker
  module_function

  def run(action_name, options = CIRCUITBOX_CONFIGURATION)
    performed = false
    result = nil
    Circuitbox.circuit(action_name, options).run do
      performed = true
      result = yield
    end
    result
  rescue Circuitbox::OpenCircuitError
    Observer.counter(:postpaid_circuit_breaker, 1, status: :open, action_name: action_name)
    raise Exceptions::CircuitOpen.new
  rescue Circuitbox::ServiceFailureError => e
    original_error = e.original
    status = case original_error
             when RestClient::Exceptions::OpenTimeout
               :open_timeout
             when RestClient::Exceptions::ReadTimeout
               :read_timeout
             else
               :service_failure
             end
    Observer.counter(:postpaid_circuit_breaker, 1, status: status, error_class: original_error.class.to_s, action_name: action_name)
    raise original_error
  rescue Redis::BaseError, Redis::FutureNotReady => e # redis failed
    status = performed ? (result.present? ? :result_present : :service_error) : :action_not_performed
    Observer.counter(:postpaid_circuit_breaker, 1, status: :redis_failure, error_class: e.class.to_s, action_name: action_name)
    LogBook.error(e.message, %w[circuitbox redis failure], action_name: action_name)
    case status
    when :action_not_performed
      yield
    when :result_present
      result
    when :service_error
      raise Exceptions::InternalError
    end
  rescue StandardError => e
    Observer.counter(:postpaid_circuit_breaker, 1, status: :error, error_class: e.class.to_s, action_name: action_name)
    LogBook.error(e.message, %w[circuitbox failure], action_name: action_name)
    raise e
  end
end
