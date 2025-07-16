# frozen_string_literal: true

module Channel
  module Tektaya
    class Base
      include Channel::Tektaya::Helpers::BuyerType
      include Channel::Tektaya::Helpers::Constants
      include Channel::Tektaya::Helpers::ResponseCode
      include PostpaidTransactionUtility
      include CachePartnerResponseUtility

      # Constants
      TIMEOUT_SECONDS            = Channel::Config::DEFAULT_TIMEOUT_TIME_SECONDS
      MAX_REQUEST_ATTEMPTS       = Channel::Config::DEFAULT_RETRY_ATTEMPTS

      CIRCUITBOX_CONFIGURATION = {
        exceptions: [Exceptions::SocketConnectionTimeout, RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT],
        sleep_window: CIRCUITBOX_SLEEP_WINDOW,
        time_window: CIRCUITBOX_TIME_WINDOW,
        volume_threshold: CIRCUITBOX_VOLUME_THRESHOLD,
        error_threshold: CIRCUITBOX_ERROR_THRESHOLD
      }.freeze

      # object can only be :
      # - form object
      # - transaction object
      def initialize(object)
        @object = object
      end

      def request(url, payload, action: 'request', with_retry: true)
        attempts ||= 1
        start_time = ::Time.current
        request_log = {
          url: url,
          payload: payload.except(:password, :sessionkey),
          track_id: @object.customer_number
        }

        if ::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya.active?
          raw_response = ::CircuitBreaker.run(:tektaya_inquiry, CIRCUITBOX_CONFIGURATION) do
            Channel::Connection::Http.post(url, nil, payload, {}, { timeout: TIMEOUT_SECONDS })
          end
        else
          raw_response = Channel::Connection::Http.post(url, nil, payload, {}, { timeout: TIMEOUT_SECONDS })
        end

        response     = JSON.parse(raw_response.body).with_indifferent_access
        response
      rescue Exceptions::CircuitOpen => e
        status = :open
        error  = e
        raise
      rescue RestClient::Exceptions::Timeout => e
        status = :timeout
        error  = e
        raise
      rescue RestClient::Exception => e
        status = :error
        error  = e
        raise
      rescue StandardError => e
        error  = e
        raise
      ensure
        # Publish metric
        duration      = ::Time.current - start_time
        response_code = response ? response.dig('tty', 'respcode').to_s : 'error'
        status      ||= get_status_from_response_code(response_code) || :error

        publish_metric(action, status, response_code, duration)

        # Cache Response Code
        cache_partner_response(product_type.to_s, action, partner_name, request_log[:track_id], response_code)

        # Publish log
        error ||= nil
        publish_log(action, request_log, response, status, attempts, error)
      end

      def can_confirm?
        false
      end

      def product_type
        nil
      end

      private

      def partner_name
        class_name_array = self.class.name.split('::').map { |s| s.underscore }
        class_name_array.second
      end

      def buyer_type
        if @object.is_bukaconnect?
          BUKACONNECT_BUYER_TYPE
        elsif @object.is_mitra?
          MITRA_BUYER_TYPE
        else
          NORMAL_BUYER_TYPE
        end
      end


      # session_key is get from login to Tektaya
      # login flow: app/services/channel/tektaya/helpers/login.rb
      def retrieve_session_key
        redis_key = determine_redis_key(buyer_type)
        RedisOlympus.get(redis_key)
      end

      def publish_metric(action, status, response_code, duration)
        tags = {
          action: action,
          partner: 'tektaya',
          product: product_type,
          biller_product: nil,  # currently it's only electricity postpaid, and does not have any biller_product
          status: status,
          response_code: response_code
        }

        Observer.histogram(Observer::Metric::PARTNER, duration, tags)
      end

      def publish_log(action, request_log, response, status, attempts = 0, error = nil)
        case status
        when :success
          tags    = %W[#{product_type.to_s} #{action.to_s} partner tektaya success]
          message = log_message(request_log[:url], request_log[:payload], response)
        when :fail_with_retry
          tags    = %W[#{product_type.to_s} #{action.to_s} partner tektaya attempt_#{attempts}]
          message = log_message(request_log[:url], request_log[:payload], response, error)
        when :failed, :error
          tags    = %W[#{product_type.to_s} #{action.to_s} partner tektaya #{status.to_s}]
          message = log_message(request_log[:url], request_log[:payload], response, error)
        end

        log_request(tags, message, request_log[:track_id])
      end

      def log_message(url, payload, response, error = nil)
        buyer_type_config = retrieve_buyer_type_config(buyer_type)

        {
          url: url,
          payload: payload,
          response: response,
          error: error,
          buyer_type: buyer_type_config[:buyer_type]
        }.to_s
      end
    end
  end
end
