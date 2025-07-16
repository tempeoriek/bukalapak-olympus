# frozen_string_literal: true

module QueryLogger
  module Sql
    SLOW_QUERY_THRESHOLD = ENV.fetch('SLOW_QUERY_THRESHOLD', 0.5).to_f
    
    def self.log(start, finish, payload)
      query = payload[:sql].strip
      return if query =~ /(STRICT_ALL_TABLES|CREATE|DROP|BEGIN|COMMIT|RELEASE|ROLLBACK|SHOW|GET_LOCK|information_schema|schema_migrations|database|ar_internal_metadata)/

      if query.starts_with?('SELECT')
        operation = :select
      elsif query.starts_with?('UPDATE')
        operation = :update
      elsif query.starts_with?('DELETE')
        operation = :delete
      elsif query.starts_with?('INSERT')
        operation = :insert
      else
        return
      end

      duration = finish - start
      slow_query = duration >= SLOW_QUERY_THRESHOLD
      status = payload[:exception] ? :error : :success

      details = { query: query, duration: duration, status: status }
      LogBook.info('Olympus SQL Slow Query', %w[olympus sql_slow_query], details, track_id: nil) if slow_query
      Observer.histogram(Observer::Metric::SQL_LATENCY, duration, operation: operation, slow: slow_query, status: status)
    end
  end
end
