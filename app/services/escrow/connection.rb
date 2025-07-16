require 'rest-client'

module Escrow
  class Connection
    HEADERS = {
      host: Channel::Config::BUKALAPAK_HOST,
      authorization: "Basic #{Channel::Config::BUKALAPAK_AUTH_KEY}",
      user_agent: 'Bukalapak',
      content_type: :json,
      accept: :json,
      'BL-Service': 'olympus'
    }

    REST_DEFAULT = { open_timeout: 60, timeout: 60 }.freeze
    class << self
      def send_request(opts, &block)
        RestClient::Request.execute(REST_DEFAULT.merge(opts), &block)
      end

      def get(url, query={}, headers={})
        headers = HEADERS.merge(headers)
        headers[:params] = query
        send_request({
          method: :get,
          url: url,
          headers: headers
        })
      end

      def patch(url, payload)
        send_request({
          method: :patch,
          url: url,
          payload: payload.to_json,
          headers: HEADERS,
        })
      end

      def post(url, payload)
        send_request({
          method: :post,
          url: url,
          payload: payload.to_json,
          headers: HEADERS,
        })
      end
    end
  end
end
