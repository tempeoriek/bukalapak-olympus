class GcpsPublisher
  def self.publish(topic_name, message, track_id: nil)
    topic = get_topic(topic_name)
    message = message.to_json

    res = topic.publish(message)
    log_event("Success publishing to topic #{topic_name}", %w[pubsub publish], track_id: track_id)
    true
  rescue => e
    log_error("#{e.class}: #{e.message}", %w[pubsub publish error], track_id: track_id, backtrace: e.backtrace.take(5))
    false
  end

  def self.get_topic(topic_name)
    GoogleCloudPubSub.topic(topic_name)
  end

  def self.log_event(message, tags, others={})
    context = Context.new
    log_entry = context.log_entry(message, tags, others)
    Logger2.info(log_entry)
  end

  def self.log_error(message, tags, others={})
    context = Context.new
    log_entry = context.log_entry(message, tags, others)
    Logger2.error(log_entry)
  end
end
