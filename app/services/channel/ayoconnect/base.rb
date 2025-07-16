# frozen_string_literal: true

module Channel
  module Ayoconnect
    class Base
      include Channel::Ayoconnect::Helpers::ResponseCode
      include Channel::Ayoconnect::Helpers::Constants
      include PostpaidTransactionUtility
      include CachePartnerResponseUtility
      include Action::PostpaidTransaction::Autoswitch

      # Constants
      PRODUCT_TYPE               = nil  # will be replaced by its direct subclasses
      DEFAULT_TIMEOUT_SECONDS    = 30   
      CREATE_TIMEOUT_SECONDS     = 10 # default time out for create transaction to partner
      MAX_REQUEST_ATTEMPTS       = 5
      MITRA_BUYER_TYPE           = 'mitra'
      NORMAL_BUYER_TYPE          = 'normal'

      URL_HOST             = Channel::Config::AYOCONNECT_HOST
      BUKALAPAK_API_KEY    = Channel::Config::AYOCONNECT_API_KEY
      BUKALAPAK_API_SECRET = Channel::Config::AYOCONNECT_API_SECRET
      MITRA_API_KEY        = Channel::Config::AYOCONNECT_MITRA_API_KEY
      MITRA_API_SECRET     = Channel::Config::AYOCONNECT_MITRA_API_SECRET

      INQUIRY_URL      = '/api/v2/bill/check'.freeze
      CHECK_STATUS_URL = '/api/v2/bill/status'.freeze
      PAYMENT_URL      = '/api/v2/bill/payment'.freeze
      API_VERSION      = nil


      CIRCUITBOX_CONFIGURATION = {
        exceptions: [Exceptions::SocketConnectionTimeout, RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT],
        sleep_window: CIRCUITBOX_SLEEP_WINDOW,
        time_window: CIRCUITBOX_TIME_WINDOW,
        volume_threshold: CIRCUITBOX_VOLUME_THRESHOLD,
        error_threshold: CIRCUITBOX_ERROR_THRESHOLD
      }.freeze

      def inquiry(payload, inquiry_url = INQUIRY_URL)
        url = URL_HOST + inquiry_url
        request_log = {
          url: url,
          payload: payload,
          track_id: payload[:accountNumber]
        }

        wrap_request(:inquiry, request_log) do
          token = generate_request_token(payload)
          headers = request_headers(token)

          if ::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect.active?
            response = ::CircuitBreaker.run(:ayoconnect_inquiry, CIRCUITBOX_CONFIGURATION) do
              Channel::Connection::Http.post(url, nil, {}, headers, { timeout: DEFAULT_TIMEOUT_SECONDS })
            end
          else
            response = Channel::Connection::Http.post(url, nil, {}, headers, { timeout: DEFAULT_TIMEOUT_SECONDS })
          end

          @result  = JSON.parse(response.body).with_indifferent_access

          if inquiry_request_fail?(@result['responseCode'])
            autoswitch_status = inquiry_request_partner_fail?(@result['responseCode']) ? :failed : :success
            record_autoswitch_value('inquiry', autoswitch_status, @product_type)

            raise_inquiry_error!(@result['responseCode']) 
          end
        end
      end

      def create(payload, payment_url = PAYMENT_URL)
        url = URL_HOST + payment_url
        request_log = {
          url: url,
          payload: payload,
          track_id: payload[:accountNumber]
        }
        wrap_request(:payment, request_log) do
          token = generate_request_token(payload)
          headers = request_headers(token)

          response = Channel::Connection::Http.post(url, nil, {}, headers, { timeout: CREATE_TIMEOUT_SECONDS })
          @result  = JSON.parse(response.body).with_indifferent_access
          @result.merge!(transaction_response(@result, :payment))
        end
      end

      def check_status(payload, check_status_url = CHECK_STATUS_URL)
        url = URL_HOST + check_status_url
        request_log = {
          url: url,
          payload: payload,
          track_id: @object.id
        }

        wrap_request(:check_status, request_log) do
          begin
            token = generate_request_token(payload)
            headers = request_headers(token)

            response = Channel::Connection::Http.post(url, nil, {}, headers, { timeout: DEFAULT_TIMEOUT_SECONDS })
            @result  = JSON.parse(response.body).with_indifferent_access
            raise ::Exceptions::PartnerTransactionNotFound if transaction_not_available?(@result['responseCode'].to_s)

            @result.merge!(transaction_response(@result, :check_status))
          rescue RestClient::Exceptions::Timeout => e
            raise
          rescue RestClient::Exception => e
            publish_log(:check_status, request_log, @result, :failed, nil, e)
            raise
          end
        end
      end

      def can_confirm?
        true
      end

      def product_type
        nil
      end

      private

      # Wrapper for requests
      def wrap_request(action, request_log, max_attempts = MAX_REQUEST_ATTEMPTS)
        attempts ||= 1
        start_time = ::Time.current

        yield

        @result
      rescue RestClient::Exceptions::Timeout => e
        # Retry
        if attempts < max_attempts
          record_autoswitch_value('inquiry', :failed, product_type) if action == :inquiry

          publish_metric(action, :timeout, 'error', ::Time.current - start_time)
          publish_log(action, request_log, @result, :fail_with_retry, attempts, e)
          attempts += 1
          retry
        end

        record_autoswitch_value('inquiry', :failed, product_type) if action == :inquiry
        status = :timeout
        error  = e
        raise
      rescue RestClient::Exception => e
        # Retry
        if attempts < max_attempts
          publish_metric(action, :error, 'error', ::Time.current - start_time)
          publish_log(action, request_log, @result, :fail_with_retry, attempts, e)
          attempts += 1
          retry
        end

        status = :error
        error  = e
        raise
      rescue ::Exceptions::PartnerTransactionNotFound => e
        # Only raised when check status, expected case
        status = :pending
        raise
      rescue StandardError => e
        # prevent sending pending log and metric for check status
        status = :error if action == :check_status

        error  = e
        raise
      ensure
        # Publish metric
        duration      = ::Time.current - start_time
        response_code = @result && @result['responseCode'] ? @result['responseCode'].to_s : 'error'
        status      ||= get_status_from_response_code(action, response_code) || :error

        publish_metric(action, status, response_code, duration)

        # Save RC to cache
        customer_number = @result && @result['data']['accountNumber'] ? @result['data']['accountNumber'].to_s : 'no_number'
        cache_partner_response(product_type.to_s, action, partner_name, customer_number, response_code)

        # Publish log
        error ||= nil
        publish_log(action, request_log, @result, status, attempts, error)
      end

      # Generating a JWT token used for requests:
      #
      # First part is token header.
      # Second part is request body.
      # Third part is the combination of header and body, and encrypted with HSHA256.
      def generate_request_token(body)
        header_encoded         = Base64.strict_encode64(token_headers.to_json).gsub('+', '-').gsub(/=+$/, '').gsub('/', '_')
        body_encoded           = Base64.strict_encode64(body.to_json).gsub('+', '-').gsub(/=+$/, '').gsub('/', '_')
        bearer_encoded         = Base64.strict_encode64(generate_bearer(header_encoded, body_encoded)).gsub('+', '-').gsub(/=+$/, '').gsub('/', '_')

        "#{header_encoded}.#{body_encoded}.#{bearer_encoded}"
      end

      # This is the first field for token used in requests.
      # It's different from request headers.
      def token_headers
        {
          alg: "HS256",
          typ: "JWT"
        }
      end

      # Request headers, be sure to pass generated token here
      def request_headers(token)
        {
          'Content-Type' => 'application/json',
          'KEY'          => get_api_key,
          'TOKEN'        => token,
          'VERSION'      => self.class::API_VERSION
        }
      end

      # Bearer is combination of encoded header and body, encrypted with secret key.
      def generate_bearer(header, body)
        secret_key = get_secret_key
        data       = "#{header}.#{body}"

        OpenSSL::HMAC.digest('sha256', secret_key, data)
      end

      def get_api_key
        @object.is_mitra? ? MITRA_API_KEY : BUKALAPAK_API_KEY
      end

      def get_secret_key
        @object.is_mitra? ? MITRA_API_SECRET : BUKALAPAK_API_SECRET
      end

      def buyer_type
        @object.is_mitra? ? MITRA_BUYER_TYPE : NORMAL_BUYER_TYPE
      end

      def publish_metric(action, status, response_code, duration)
        tags = {
          action: action,
          partner: 'ayoconnect',
          product: self.class::PRODUCT_TYPE,
          biller_product: nil,  # currently it's only electricity postpaid, and does not have any biller_product
          status: status,
          response_code: response_code
        }

        Observer.histogram(Observer::Metric::PARTNER, duration, tags)
      end

      def publish_log(action, request_log, response, status, attempts = 0, error = nil)
        case status
        when :success, :pending
          tags    = %W[#{self.class::PRODUCT_TYPE.to_s} #{action.to_s} partner ayoconnect success]
          message = log_message(request_log[:url], request_log[:payload], response)
        when :fail_with_retry
          tags    = %W[#{self.class::PRODUCT_TYPE.to_s} #{action.to_s} partner ayoconnect attempt_#{attempts}]
          message = log_message(request_log[:url], request_log[:payload], response, error)
        when :failed, :error
          tags    = %W[#{self.class::PRODUCT_TYPE.to_s} #{action.to_s} partner ayoconnect #{status.to_s}]
          message = log_message(request_log[:url], request_log[:payload], response, error)
        end

        log_request(tags, message, request_log[:track_id])
      end

      def log_message(url, payload, response, error = nil)
        {
          url: url,
          payload: payload,
          response: response,
          error: error,
          buyer_type: buyer_type
        }.to_s
      end

      def transaction_response(response, action)
        {
          customer_number: response[:data][:accountNumber],
          partner_transaction_id: response[:data][:transactionId]&.to_s,
          status: PARTNER_STATUS[AYOCONNECT][get_status_from_response_code(action, response[:responseCode]).to_s]
        }
      end

      def partner_name
        class_name_array = self.class.name.split('::').map { |s| s.underscore }
        class_name_array.second
      end
    end
  end
end
