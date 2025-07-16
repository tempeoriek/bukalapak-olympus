Honeybadger.configure do |config|
  config.api_key = ENV["HONEYBADGER_API_KEY"]

  #uncomment line below to enable error reporting in development
  #config.development_environments = ['test', 'cucumber']
end
