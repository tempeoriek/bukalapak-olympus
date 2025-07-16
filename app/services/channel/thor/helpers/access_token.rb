module Channel
  module Thor
    module Helpers
      module AccessToken
        ACCESS_TOKEN_CACHE_KEY = 'THOR_ACCESS_TOKEN'.freeze
        ACCESS_TOKEN_SCOPE = 'transaction.water-bill-transaction.read transaction.water-bill-transaction.write transaction.postpaid-electricity-transaction.read transaction.postpaid-electricity-transaction.write transaction.cc-bill-transaction.read transaction.cc-bill-transaction.write'.freeze
        ACCESS_TOKEN_SHORTEN = 60 * 5 # 5 minutes in seconds
        OAUTH_URL = "#{::Channel::Config::THOR_AUTH_HOST}/oauth2/token".freeze

        def refresh_jwt_token
          delete_cache_jwt_token
          get_jwt_token
        end

        def delete_cache_jwt_token
          Rails.cache.delete(ACCESS_TOKEN_CACHE_KEY)
        end

        def get_jwt_token
          jwt_token = Rails.cache.read(ACCESS_TOKEN_CACHE_KEY)
          return jwt_token if jwt_token.present?

          generate_jwt_token
        end

        private

        def generate_jwt_token
          payload = {
            grant_type: 'client_credentials',
            scope: ACCESS_TOKEN_SCOPE,
          }

          response = Channel::Connection::Http.post(OAUTH_URL, auth, payload, oauth_header, restclient_options)
          body = JSON.parse(response.body).with_indifferent_access

          save_token_to_cache(body)

          body['access_token']
        rescue RestClient::Exceptions::OpenTimeout => e
          status = :timeout
          raise e
        rescue StandardError => e
          raise e
        end

        def auth
          string_to_encode = "#{::Channel::Config::THOR_CLIENT_ID}:#{::Channel::Config::THOR_CLIENT_SECRET}"
          "Basic #{Base64.strict_encode64(string_to_encode)}"
        end

        def oauth_header
          {
            content_type: 'application/x-www-form-urlencoded',
            accept: 'application/x-www-form-urlencoded',
          }
        end

        def save_token_to_cache(response_body)
          cache_ttl = response_body['expires_in'] - ACCESS_TOKEN_SHORTEN
          Rails.cache.write(ACCESS_TOKEN_CACHE_KEY, response_body['access_token'], expires_in: cache_ttl.positive? ? cache_ttl : response_body['expires_in'])
        end

        def restclient_options
          {
            timeout: 20,
            encode_query_string: true
          }
        end
      end
    end
  end
end
