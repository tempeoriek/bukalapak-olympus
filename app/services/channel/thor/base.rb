module Channel
  module Thor
    class Base
      include Channel::Thor::Helpers::AccessToken
      include Channel::Thor::Helpers::ResponseCode
      include PostpaidTransactionUtility
      include CachePartnerResponseUtility
      include Action::PostpaidTransaction::Autoswitch

      PRODUCT_TYPE               = nil
      DEFAULT_TIMEOUT_SECONDS    = 60
      MITRA_BUYER_TYPE           = 'mitra'.freeze
      NORMAL_BUYER_TYPE          = 'normal'.freeze
      MAX_REQUEST_ATTEMPTS       = 5
      MAX_GENERATE_TOKEN_ATTEMPS = 2

      CIRCUITBOX_SLEEP_WINDOW     = 60
      CIRCUITBOX_TIME_WINDOW      = 30
      CIRCUITBOX_VOLUME_THRESHOLD = 10
      CIRCUITBOX_ERROR_THRESHOLD  = 50

      CIRCUITBOX_CONFIGURATION = {
        exceptions: [Exceptions::SocketConnectionTimeout, RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout, Errno::ECONNREFUSED, Errno::ETIMEDOUT],
        sleep_window: CIRCUITBOX_SLEEP_WINDOW,
        time_window: CIRCUITBOX_TIME_WINDOW,
        volume_threshold: CIRCUITBOX_VOLUME_THRESHOLD,
        error_threshold: CIRCUITBOX_ERROR_THRESHOLD
      }.freeze

      INQUIRY_URL            = nil
      CREATE_TRANSACTION_URL = nil
      CONFIRM_URL            = nil

      THOR_RESPONSE_INQUIRY_KEY = nil
      THOR_RESPONSE_TRANSACTION_KEY = nil

      def inquiry(payload)
        url = ::Channel::Config::THOR_HOST + self.class::INQUIRY_URL
        request_log = {
          url: url,
          payload: payload,
          track_id: payload.dig(:customer_number) || 0
        }

        wrap_request(:inquiry, request_log) do
          if circuit_breaker_active?
            @response = ::CircuitBreaker.run(:thor_inquiry, CIRCUITBOX_CONFIGURATION) do
              Channel::Connection::Http.post(url, access_token, payload, {}, { timeout: DEFAULT_TIMEOUT_SECONDS })
            end
          else
            @response = Channel::Connection::Http.post(url, access_token, payload, {}, { timeout: DEFAULT_TIMEOUT_SECONDS })
          end

          response_body = JSON.parse(@response.body).with_indifferent_access
          @result = unwrap_response(response_body, self.class::THOR_RESPONSE_INQUIRY_KEY)

          response_code = @result.dig(:response_code)
          if failed_response?(response_code)
            autoswitch_status = partner_failed_response?(response_code) ? :failed : :success
            autoswitch_options = {}
            autoswitch_options[:operator_id] = @object.operator.id if @product_type == 'pdam'
            record_autoswitch_value('inquiry', autoswitch_status, @product_type, autoswitch_options)

            raise_failed_inquiry!(response_code, self.class::PRODUCT_TYPE.to_s, @result.dig(:message)) 
          end
        end
      end

      def create(payload)
        url = ::Channel::Config::THOR_HOST + self.class::CREATE_TRANSACTION_URL
        request_log = {
          url: url,
          payload: payload,
          track_id: payload.dig(:customer_number) || 0
        }
        
        wrap_request(:create_transaction, request_log) do
          @result = begin
            advice_response = advice_transaction(payload[:order_id])
            return advice_response unless TRANSACTION_UNAVAILABLE_RC.include?(advice_response[:response_code])
            
            @response = Channel::Connection::Http.post(url, access_token, payload, {}, { timeout: DEFAULT_TIMEOUT_SECONDS }) 
            response_body = JSON.parse(@response.body).with_indifferent_access
            unwrap_response(response_body, self.class::THOR_RESPONSE_TRANSACTION_KEY)     
          end

          @result.merge!(transaction_response(:create_transaction, @result))
        end
      end

      def get_transaction_by_id(transaction_id)
        url = ::Channel::Config::THOR_HOST + self.class::CONFIRM_URL + transaction_id.to_s
        request_log = {
          url: url,
          track_id: transaction_id || 0
        }

        wrap_request(:get_transaction_by_id, request_log) do
          @result = advice_transaction(transaction_id)
          raise ::Exceptions::PartnerTransactionNotFound if TRANSACTION_UNAVAILABLE_RC.include?(@result[:response_code])

          @result.merge!(transaction_response(:get_transaction_by_id, @result))
        end
      end

      def can_confirm?
        true
      end

      private

      def advice_transaction(transaction_id)
        url = ::Channel::Config::THOR_HOST + self.class::CONFIRM_URL + transaction_id.to_s
        @response = Channel::Connection::Http.get(url, access_token)

        response_body = JSON.parse(@response.body).with_indifferent_access
        unwrap_response(response_body, self.class::THOR_RESPONSE_TRANSACTION_KEY)
      end

      def unwrap_response(response, key)
        response[key.to_sym].present? ? response[key.to_sym] : response
      end

      def wrap_request(action, request_log, max_attempts = MAX_REQUEST_ATTEMPTS)
        attempts ||= 1
        start_time = ::Time.current

        yield

        raise ::Exceptions::Thor::Unauthorized if unauthorized?
        raise ::Exceptions::Thor::Forbidden if  forbidden?

        @result
      rescue RestClient::Exceptions::Timeout => e
        autoswitch_options = {}
        autoswitch_options[:operator_id] = @object.operator.id if @product_type == 'pdam'

        # Retry
        if attempts < max_attempts
          record_autoswitch_value('inquiry', :failed, @product_type, autoswitch_options) if action == :inquiry
          publish_metric(action, :timeout, 'error', ::Time.current - start_time)
          publish_log(action, request_log, @result, :retry, attempts, e)
          attempts += 1
          retry
        end

        record_autoswitch_value('inquiry', :failed, @product_type, autoswitch_options) if action == :inquiry
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
      rescue ::Exceptions::Thor::Forbidden => e
        delete_cache_jwt_token

        status = :error
        error  = e
        raise
      rescue ::Exceptions::Thor::Unauthorized
        # Retry if access token expired
        if attempts < MAX_GENERATE_TOKEN_ATTEMPS
          publish_metric(action, :error, 'error', ::Time.current - start_time)
          publish_log(action, request_log, @result, :fail_with_retry, attempts, e)
          refresh_jwt_token
          attempts += 1
          retry
        end

        status = :error
        error  = e
        raise
      rescue StandardError => e
        error = e
        raise
      ensure
        duration = ::Time.current - start_time
        response_code = @result && @result['response_code'] ? @result['response_code'] : 'error'
        status      ||= get_status_from_response_code(action, response_code) || :error

        # publish metric
        publish_metric(action, status, response_code, duration)

        customer_number = @result && @result['customer_number'] ? @result['customer_number'].to_s : 'no_number'
        cache_partner_response(self.class::PRODUCT_TYPE.to_s, action, THOR.to_s, customer_number, response_code)

        # publish log
        error ||= nil
        publish_log(action, request_log, @result, status, attempts, error)
      end

      def access_token
        "Bearer #{get_jwt_token}"
      end

      def forbidden?
        @response.net_http_res.class == Net::HTTPForbidden
      end

      def unauthorized?
        @response.net_http_res.class == Net::HTTPUnauthorized
      end

      def circuit_breaker_active?
        Toggle::CircuitBreaker::Thor.active?
      end

      def transaction_response(action, response)
        {
          status: PARTNER_STATUS[THOR][get_status_from_response_code(action, response['response_code']).to_s]
        }
      end

      def buyer_type
        @object.is_mitra? ? MITRA_BUYER_TYPE : NORMAL_BUYER_TYPE
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

      def publish_log(action, request_log, response, status, attempts = 0, error = nil)
        case status
        when :retry
          tags    = %W[#{self.class::PRODUCT_TYPE} #{action} partner thor attempt_#{attempts}]
          message = log_message(request_log[:url], request_log[:payload], response, error)
        else
          tags    = %W[#{self.class::PRODUCT_TYPE} #{action} partner thor #{status}]
          message = log_message(request_log[:url], request_log[:payload], response, error)
        end

        log_request(tags, message, request_log[:track_id])
      end

      def publish_metric(action, status, response_code, duration)
        tags = {
          action: action,
          partner: 'thor',
          product: self.class::PRODUCT_TYPE,
          biller_product: biller_product,
          status: status,
          response_code: response_code
        }

        Observer.histogram(Observer::Metric::PARTNER, duration, tags)
      end

      def biller_product
        case self.class::PRODUCT_TYPE
        when 'electricity_postpaid'
          nil
        when 'pdam'
          @object&.operator&.name
        end
      end
    end
  end
end
