require 'logstash-logger'

Logger2 ||= LogStashLogger.new(
  type: :stdout,
  format: :json_lines
)

module LogBook
  module_function

  def info(message, tags, others={}, track_id: nil)
    others[:track_id] = track_id if track_id
    log_entry = Context.new.log_entry(message, tags, others)
    Logger2.info(log_entry)
  end

  def warn(message, tags, others={}, track_id: nil)
    others[:track_id] = track_id if track_id
    log_entry = Context.new.log_entry(message, tags, others)
    Logger2.warn(log_entry)
  end

  def error(message, tags, backtrace, others={}, track_id: nil)
    tags << 'error' # a bit redundant because severity will be set to 'ERROR'
    others[:track_id] = track_id if track_id
    others[:backtrace] = backtrace
    log_entry = Context.new.log_entry(message, tags, others)
    Logger2.error(log_entry)
  end
end
