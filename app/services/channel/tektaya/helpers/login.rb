# frozen_string_literal: true

module Channel
  module Tektaya
    module Helpers
      class Login
        include BuyerType
        include Constants
        include PostpaidTransactionUtility
        include ResponseCode

        attr_reader :buyer_type

        ALLOWED_BUYER_TYPES = [
          MITRA_BUYER_TYPE,
          NORMAL_BUYER_TYPE,
          BUKACONNECT_BUYER_TYPE
        ].freeze
        LOGIN_URL           = "#{TEKTAYA_HOST}#{TEKTAYA_LOGIN_URL}"

        # Buyer type is either MITRA_BUYER_TYPE or NORMAL_BUYER_TYPE
        def initialize(buyer_type)
          @buyer_type = buyer_type
        end

        def request
          validate_buyer_type!

          begin
            start_time   = ::Time.current
            payload      = login_payload

            raw_response = Channel::Connection::Http.post(LOGIN_URL, nil, payload, {}, { timeout: Channel::Config::DEFAULT_TIMEOUT_TIME_SECONDS })
            response     = JSON.parse(raw_response.body).with_indifferent_access
            session_key  = response.dig('tty', 'sessionkey')

            raise  ::Exceptions::PartnerIssue.new('Fail to retrieve session key for Tektaya') if session_key.blank?

            put_session_key(session_key)
          rescue StandardError => e
            error  = e
            raise
          ensure
            # Publish metric
            duration      = ::Time.current - start_time
            response_code = response ? response.dig('tty', 'respcode').to_s : 'error'
            status        = response_code == '00' ? :success : :error

            publish_metric(status, response_code, duration)

            # Publish log
            error ||= nil
            publish_log(payload, response, status, error)
          end
        end

        private

        def validate_buyer_type!
          raise ::Exceptions::PartnerIssue.new('Invalid buyer type for Tektaya') unless ALLOWED_BUYER_TYPES.include?(buyer_type)
        end

        def login_payload
          configs = retrieve_buyer_type_config(buyer_type)

          {
            mti: LOGIN_MTI,
            userid: configs[:user_id],
            password: configs[:password],
            bit62: configs[:bit62]
          }
        end

        def publish_metric(status, response_code, duration)
          tags = {
            action: 'login',
            partner: 'tektaya',
            status: status,
            response_code: response_code
          }
  
          Observer.histogram(::Observer::Metric::PARTNER, duration, tags)
        end

        def publish_log(payload, response, status, error = nil)
          case status
          when :success
            tags    = %W[login partner tektaya success]
            message = log_message('Success login.')
          when :failed
            tags    = %W[login partner tektaya failed]
            message = log_message("Failed to login | Payload: #{payload.except(:password, :bit62)} | Response: #{response}", error)
          when :error
            tags    = %W[login partner tektaya error]
            message = log_message('Error to login to partner', error)
          end
  
          log_request(tags, message, DateTime.now.strftime('%Y-%m-%d'))
        end

        def put_session_key(session_key)
          redis_key = determine_redis_key(buyer_type)
          ::RedisOlympus.set(redis_key, session_key)
        end

        def log_message(message, error = nil)
          {
            message: message,
            error: error,
            buyer_type: buyer_type
          }.to_s
        end
      end
    end
  end
end
