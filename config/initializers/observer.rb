# frozen_string_literal: true

require 'datadog/statsd'

DatadogMetric ||= Datadog::Statsd.new(
  ENV.fetch('DD_AGENT_HOST', '127.0.0.1'),
  ENV.fetch('DD_AGENT_PORT','8125'),
  namespace: ENV.fetch('DD_AGENT_NAMESPACE', 'olympus')
)

module Observer
  DEFAULT_TAGS      = { service: 'olympus' }

  module Metric
    # Add new metric here
    API                           = :postpaid_api_latency
    PARTNER                       = :postpaid_partner_latency
    RECURRENCE                    = :postpaid_recurrence_transaction
    SIEVEX                        = :postpaid_sievex_counter
    STATE                         = :postpaid_service_transaction_state
    STUCK                         = :postpaid_stuck_transaction
    WORKER                        = :postpaid_worker_latency
    GMV                           = :postpaid_transaction_gmv
    REVENUE                       = :postpaid_transaction_revenue
    TAGLIS_BALANCE                = :postpaid_electricity_postpaid_balance
    TAGLIS_THRESHOLD              = :postpaid_electricity_postpaid_threshold
    TAGLIS_BALANCE_MITRA          = :postpaid_electricity_postpaid_balance_mitra
    TAGLIS_THRESHOLD_MITRA        = :postpaid_electricity_postpaid_threshold_mitra
    TAGLIS_BALANCE_BUKACONNECT    = :postpaid_electricity_postpaid_balance_bukaconnect
    TAGLIS_THRESHOLD_BUKACONNECT  = :postpaid_electricity_postpaid_threshold_bukaconnect
    INSUFFICIENT_CCB_BALANCE      = :postpaid_insufficient_ccb_balance
    GENERAL_CIRCUIT_BREAKER       = :postpaid_general_circuit_breaker
    SQL_LATENCY                   = :sql_query_latency_seconds
    TIME_TO_SUCCEED               = :postpaid_paid_to_remit
    TAGLIS_AUTO_SWITCH            = :postpaid_electricity_postpaid_auto_switch
    PDAM_AUTO_SWITCH              = :pdam_auto_switch
  end

  module_function

  def counter(name, value, tags={})
    tags.merge!(DEFAULT_TAGS)
    DatadogMetric.increment(name, by: value, tags: tags_hash(tags))
  end

  def gauge(name, value, tags={})
    tags.merge!(DEFAULT_TAGS)
    DatadogMetric.gauge(name, value, tags: tags_hash(tags))
  end

  def histogram(name, value, tags={})
    tags.merge!(DEFAULT_TAGS)
    DatadogMetric.histogram(name, value, tags: tags_hash(tags))
  end

  def distribution(name, value, tags={})
    tags.merge!(DEFAULT_TAGS)
    DatadogMetric.distribution(name, value, tags: tags_hash(tags))
  end

  def measure(name, tags)
    start_time = Time.now
    status = 'ok'
    begin
      yield
    rescue => e
      status = 'error'
      raise e
    ensure
      duration = Time.now - start_time # in seconds
      histogram(name, duration, tags.merge(status: status))
    end
  end

  def tags_hash(hash)
    hash.map{ |k,v| "#{k}:#{v}" }
  end
end
