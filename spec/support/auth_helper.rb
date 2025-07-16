module AuthHelper
  def http_login
    username = ENV['BUKALAPAK_USERNAME']
    password = ENV['BUKALAPAK_PASSWORD']
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end

  def http_login_new
    username = ENV['OLYMPUS_BASIC_USERNAME']
    password = ENV['OLYMPUS_BASIC_PASSWORD']
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end

  def http_login_alt
    username = ENV['OLYMPUS_BASIC_USERNAME']
    password = ENV['OLYMPUS_BASIC_ALT_PASSWORD']
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end

  def http_login(username, password)
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(username, password)
  end
end
