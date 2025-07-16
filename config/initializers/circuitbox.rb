Circuitbox.configure do |config|
  unless ENV['RAILS_ENV'] == 'test'
    # there is no redis in gitlab runner, so use memory store instead
    config.default_circuit_store = Moneta.new(:Redis, backend: Redis.new(host: ENV['REDIS_HOST'], port: ENV['REDIS_PORT'], db: ENV['REDIS_DB']), prefix: 'circuitbox:', threadsafe: true)
  end
  config.default_logger = Logger.new('/dev/null') # silence debug
end

CIRCUITBOX_CONFIGURATION = {
  exceptions: [RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout],
  sleep_window: ENV['CIRCUITBOX_SLEEP_WINDOW'].to_i,
  time_window: ENV['CIRCUITBOX_TIME_WINDOW'].to_i,
  volume_threshold: ENV['CIRCUITBOX_VOLUME_THRESHOLD'].to_i,
  error_threshold: ENV['CIRCUITBOX_ERROR_THRESHOLD'].to_i
}.freeze

circuit_open_message = 'Circuit %s opened, connection held until %s'
ActiveSupport::Notifications.subscribe('circuit_open') do |_name, _start, _finish, _id, payload|
  circuit = payload[:circuit]
  end_time = (Time.now + CIRCUITBOX_CONFIGURATION[:sleep_window]).strftime('%k:%M:%S')
  message = format(circuit_open_message, circuit, end_time)
  tags = ['circuitbox', circuit, 'opened']
  LogBook.info(message, tags)
end

circuit_close_message = 'Circuit %s closed, connection continued'
ActiveSupport::Notifications.subscribe('circuit_close') do |_name, _start, _finish, _id, payload|
  circuit = payload[:circuit]
  message = circuit_close_message % circuit
  tags = ['circuitbox', circuit, 'closed']
  LogBook.info(message, tags)
end
