module LoggerUtility

  def start_worker_log(message, tags, others={})
    context = Context.new
    log_entry = context.log_entry(message, tags, others)
    Logger2.info(log_entry)
  end

  def stop_worker_log(message, tags, others={})
    context = Context.new
    log_entry = context.log_entry(message, tags, others)
    Logger2.info(log_entry)
  end

  def failed_worker_log(message, tags, others={})
    context = Context.new
    log_entry = context.log_entry(message, tags, others)
    Logger2.error(log_entry)
  end

  def info_worker_log(message, tags, others={})
    context = Context.new
    log_entry = context.log_entry(message, tags, others)
    Logger2.info(log_entry)
  end

  def warn_worker_log(message, tags, others={})
    context = Context.new
    log_entry = context.log_entry(message, tags, others)
    Logger2.warn(log_entry)
  end

  def log_event(message, tags, others={})
    context = Context.new
    log_entry = context.log_entry(message, tags, others)
    Logger2.info(log_entry)
  end

  def log_error(message, tags, others={})
    context = Context.new
    log_entry = context.log_entry(message, tags, others)
    Logger2.error(log_entry)
  end
end
