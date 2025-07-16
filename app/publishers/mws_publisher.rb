class MwsPublisher
  def self.publish(job_name, routing_key, payload, options={})
    payload  = payload.to_json
    delay    = options[:delay].to_i
    priority = options[:priority] || 'normal'

    response, error = MwsApiClient::Job.enqueue(job_name, delay, routing_key, priority, payload)

    return nil if error.present?
    return response
  rescue MwsApiClient::Errors::ConnectionFailed
    return nil
  end
end
