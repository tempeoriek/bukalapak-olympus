SieveX.configure do |config|
  config.api_url  = ENV['SIEVEX_HOST']
  config.username = ENV['SIEVEX_USERNAME']
  config.password = ENV['SIEVEX_PASSWORD']
  config.user_agent = 'Olympus v1'
  config.timeout = 2
  config.open_timeout = 1
end