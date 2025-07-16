module Escrow
  class UserDetail
    USER_DETAIL_URL = "#{Channel::Config::BUKALAPAK_ENDPOINT}_internal/users/id/%s".freeze

    def self.get(user_id)
      url = USER_DETAIL_URL % user_id
      response = Escrow::Connection.get(url)
      build_response(response)
    end

    private

    def self.build_response(response)
      response = (JSON.parse(response).with_indifferent_access)[:data]
      {
        user_id: response[:id],
        username: response[:username],
        name: response[:name],
        email: response[:email],
        phone: response[:phone]
      }
    end
  end
end
