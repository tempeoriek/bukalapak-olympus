module Authenticate
  extend ActiveSupport::Concern
  include Postpaid::Constant

  private

  def http_basic_authenticate
    authenticate_or_request_with_http_basic 'Authentication Required' do |username, password| 
      (username == ENV['BUKALAPAK_USERNAME'] && password == ENV['BUKALAPAK_PASSWORD']) || (username == ENV['OLYMPUS_BASIC_USERNAME'] && ([ENV['OLYMPUS_BASIC_PASSWORD'], ENV['OLYMPUS_BASIC_ALT_PASSWORD']].include? password))
    end
  end

  def http_basic_authenticate_partner(partner)
    authenticate_or_request_with_http_basic 'Authentication Required' do |username, password|
      username == PARTNER_BASIC_AUTH_MAP[partner][:username] && password == PARTNER_BASIC_AUTH_MAP[partner][:password]
    end
  end

  def get_token(header_auth)
    pattern = /^Token /
    header_auth.gsub(pattern, '') if header_auth && header_auth.match(pattern)
  end

  def is_role_authorize?(role)
    AUTHORIZED_ROLES.include?(role)
  end

  def exclusive_authorized_role?(role)
    EXCLUSIVE_AUTHORIZED_ROLES.include?(role)
  end
end
