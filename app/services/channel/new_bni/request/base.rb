# frozen_string_literal: true

module Channel
  module NewBNI
    module Request
      class Base
        include PostpaidTransactionUtility

        # Constants
        NEW_BNI_ACCESS_TOKEN_KEY   = 'new_bni_access_token'
        TOKEN_REQUEST_MAX_ATTEMPTS = 5
        PRODUCT_TYPE = 'credit-card-bill'
        ACCOUNT_NUM = Channel::Config::NEW_BNI_ACCOUNT_NUM
        BNI_BILLER_CODE = Channel::Config::BNI_BILLER_CODE.freeze

        # API Token Basic Auth
        TOKEN_BASIC_USERNAME = Channel::Config::NEW_BNI_TOKEN_BASIC_USERNAME
        TOKEN_BASIC_PASSWORD = Channel::Config::NEW_BNI_TOKEN_BASIC_PASSWORD

        # Token Value
        ACCESS_TOKEN_URL = Channel::Config::NEW_BNI_ACCESS_TOKEN_URL
        API_KEY          = Channel::Config::NEW_BNI_API_KEY
        API_SECRET_KEY   = Channel::Config::NEW_BNI_API_SECRET_KEY

        def retrieve_access_token
          token = Keystore.get(NEW_BNI_ACCESS_TOKEN_KEY)
          return token if token.present?

          result = request_token_data
          Keystore.set(NEW_BNI_ACCESS_TOKEN_KEY, result[:access_token], result[:expires_in])
          result[:access_token]
        end

        # Signature is a value that will be used in the request body.
        # The signature will follow the format of JWT.
        # NOTE: Request body provided in this method must match with the payload.
        def generate_signature(payload)
          header_encoded    = Base64.strict_encode64(token_headers.to_json).gsub('+', '-').gsub(/=+$/, '').gsub('/', '_')
          body_encoded      = Base64.strict_encode64(payload.to_json).gsub('+', '-').gsub(/=+$/, '').gsub('/', '_')
          signature_encoded = Base64.strict_encode64(generate_jwt_signature(header_encoded, body_encoded)).gsub('+', '-').gsub(/=+$/, '').gsub('/', '_')

          "#{header_encoded}.#{body_encoded}.#{signature_encoded}"
        end

        # Used to generate metric tags
        def metric_tags(additional_tags = {})
          {
            partner: :new_bni,
            product_type: :credit_card_bill
          }.merge(additional_tags)
        end

        # Publish log with specified action, tag, and message
        def publish_log(action, message, track_id)
          tags = %W[credit_card_bill #{action.to_s} partner new_bni]
          tags << 'error' if message[:error].present?

          log_request(tags, message, track_id)
        end

        private

        # Header for JWT Signature
        def token_headers
          {
            alg: 'HS256',
            typ: 'JWT'
          }
        end

        # Generate JWT signature for the JWT token.
        def generate_jwt_signature(header, body)
          data       = "#{header}.#{body}"

          OpenSSL::HMAC.digest('sha256', API_SECRET_KEY, data)
        end

        def request_token_data
          attempts ||= 1
          start_time = ::Time.current

          payload = { grant_type: 'client_credentials' }
          headers = { content_type: 'application/x-www-form-urlencoded' }
          basic_auth = ::BasicAuthGenerator.generate(TOKEN_BASIC_USERNAME, TOKEN_BASIC_PASSWORD)

          # HTTP Request to API Get Token
          response = ::Channel::Connection::Http.post(ACCESS_TOKEN_URL, basic_auth, payload, headers)
          parsed_response = JSON.parse(response.body).with_indifferent_access

          status = :ok
          parsed_response
        rescue StandardError => e
          if attempts <= TOKEN_REQUEST_MAX_ATTEMPTS
            duration = ::Time.current - start_time

            Observer.histogram(Observer::Metric::PARTNER, duration, metric_tags(action: :request_token, status: :error))
            attempts += 1
            retry
          end

          status = :error
          error  = e
          raise e
        ensure
          status ||= :error
          error  ||= nil
          duration = ::Time.current - start_time

          # Publish metrics
          Observer.histogram(Observer::Metric::PARTNER, duration, metric_tags(action: :request_token, status: status))

          log_message = {
            url: ACCESS_TOKEN_URL,
            payload: payload,
            response: parsed_response,
            error: error
          }
          publish_log(:request_token, log_message, nil)
        end

        def transaction_url(trx_url)
          query = {
            access_token: retrieve_access_token
          }
          "#{trx_url}?#{query.to_query}"
        end
      end
    end
  end
end
