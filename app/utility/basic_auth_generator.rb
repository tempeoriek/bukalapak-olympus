# frozen_string_literal: true

# Class to generate a basic auth header from username and password.
# Some channels might use this.
class BasicAuthGenerator
  class << self
    def generate(username, password)
      token = Base64.strict_encode64("#{username}:#{password}")

      "Basic #{token}"
    end
  end
end
