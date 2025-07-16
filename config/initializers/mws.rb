MwsApiClient.configure do |config|
  config.mws_api_host = ENV['MWS_API_HOST']
  config.timeout = ENV['MWS_TIMEOUT']
  config.open_timeout = ENV['MWS_OPEN_TIMEOUT']
end
