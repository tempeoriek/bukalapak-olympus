class Context
  attr_accessor :request_id, :trace_id, :span_id, :parent_span_id
  attr_accessor :actor, :deadline, :retry, :trace_sampled, :application_name
  attr_accessor :client

  def initialize(&block)
    yield self if block_given?
    @request_id = generate_uuid unless @request_id
    @trace_id = generate_uuid unless @trace_id
    @span_id = generate_uuid
  end

  def generate_uuid
    SecureRandom.uuid
  end

  def full_context_hash
    {
      request_id: @request_id.to_s,
      trace_id: @trace_id.to_s,
      span_id: @span_id.to_s,
      parent_span_id: @parent_span_id.to_s,
      deadline: @deadline.to_s,
      retry: @retry.to_s,
      trace_sampled: @trace_sampled,
      client_platform: @client&.platform,
      client_version: @client&.version
    }
  end

  def full_context_log_entry(message, tags, others={})
    result = {
      message: message,
      tags: tags
    }

    result.merge!(full_context_hash)
    extend_message(result, others)
    result
  end

  def log_entry(message, tags, others={})
    result = {
      request_id: @request_id,
      message: message,
      tags: tags
    }

    extend_message(result, others)
    result
  end

  def extend_message(result, others)
    others = others.except(:request_id, :trace_id, :span_id, :parent_span_id, :deadline, :retry, :trace_sampled)
    others.each do |k, v|
      result[k.to_sym] = v.to_s # to_s makes hash very hard to read
    end
  end
end
