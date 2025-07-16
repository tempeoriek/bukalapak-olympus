module Channel
  module Sepulsa
    class Base
      include PostpaidTransactionUtility
      include ApplicationHelper
      include CachePartnerResponseUtility
      include Action::PostpaidTransaction::Autoswitch

      AUTH = 'Basic ' + Channel::Config::SEPULSA_AUTH_KEY.freeze
      MITRA_AUTH = 'Basic ' + Channel::Config::MITRA_SEPULSA_AUTH_KEY.freeze
      INQUIRY_URL = "#{Channel::Config::SEPULSA_ENDPOINT}inquire.json".freeze
      TRANSACTION_URL = "#{Channel::Config::SEPULSA_ENDPOINT}transaction.json".freeze

      ## RC Definition
      # 00 - Success
      # 10 - Pending
      # 20 - Wrong number/ number blocked/ number expired
      # 21 - Product Issue
      # 22 - Duplicate Transaction
      # 23 - Connection Timeout
      # 24 - Provider Cut Off
      # 25 - KWH is Overlimit
      # 26 - Payment Overlimit
      # 50 - Bill Already Paid/ Not Available
      # 51 - Invalid Inquiry Amount or No inquiry
      # 98 - Order Canceled by Ops
      # 99 - General Error

      SUCCESS_REQUEST_RC_LIST = Set.new(%w[00])
      PENDING_REQUEST_RC_LIST = Set.new(%w[10])
      FAIL_REQUEST_RC_LIST = Set.new(%w[20 50])
      FAIL_PARTNER_REQUEST_RC_LIST = [
        '21', # Product Issue
        '23', # Connection Timeout
        '24', # Provider Cut Off
        '99', # General Error
        'error', # error
      ]

      def inquiry(payload)
        start_time = ::Time.current
        product_type = payload[:product_type] || get_product_name_from_product_id(payload[:product_id])

        response = Channel::Connection::Http.post(INQUIRY_URL, AUTH, payload, {}, {timeout: 20})

        result = JSON.parse(response).with_indifferent_access

        # use status for checking failed or not
        unless is_boolean?(result[:status]) && result[:status] || (product_type == PHONE_CREDIT_PRODUCT && result[:response_code] == "00")
          autoswitch_options = {}
          autoswitch_options[:operator_id] = @object.operator.id if product_type == PDAM_PRODUCT
          record_autoswitch_value(
            'inquiry',
            autoswitch_status(result[:response_code]),
            product_type,
            autoswitch_options
          )

          log_error('inquiry', INQUIRY_URL, payload, result)
          raise_error(result[:response_code])
        end

        log_success('inquiry', INQUIRY_URL, payload, result)
        result
      rescue RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout => e
        autoswitch_options = {}
        autoswitch_options[:operator_id] = @object.operator.id if product_type == PDAM_PRODUCT
        record_autoswitch_value('inquiry', :failed, product_type, autoswitch_options)

        status = :timeout

        raise e
      ensure
        ## Error Cache
        response_code = result&.dig(:response_code) || "unknown_response"
        action_name = __method__
        cache_partner_response(product_type, action_name, partner_name, payload[:customer_number], response_code)

        ## Metric
        duration      = ::Time.current - start_time
        status      ||= result && result[:response_code] ? transform_response_code(result[:response_code]) : :error
        response_code = result && result[:response_code] ? result[:response_code] : 'error'
        entries = {
          action: 'inquiry',
          partner: 'sepulsa',
          product: product_type,
          biller_product: @biller_product,
          status: status,
          response_code: response_code
        }
        Observer.histogram(Observer::Metric::PARTNER, duration, entries)
      end

      def create(payload, remote_id=nil)
        start_time = ::Time.current
        product_type = payload[:product_type] || get_product_name_from_product_id(payload[:product_id])

        response = Channel::Connection::Http.post(TRANSACTION_URL, AUTH, payload.except(:product_type))
        result = JSON.parse(response).with_indifferent_access

        # use response_code for checking failed or not
        unless response_success?(result[:response_code])
          log_error('create_transaction', TRANSACTION_URL, payload, result)
          raise_error(result[:response_code])
        end

        log_success('create_transaction', TRANSACTION_URL, payload, result)

        result[:data] = result[:data] || {}
        result[:data].merge!(transaction_response(result))
      rescue RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout => e
        status = :timeout

        raise e
      ensure
        ## Cache Partner Response
        response_code = result&.dig(:response_code) || "unknown_response"
        action_name = __method__
        cache_partner_response(product_type, action_name, partner_name, remote_id, response_code)

        ## Metric
        duration      = ::Time.current - start_time
        status      ||= result && result[:response_code] ? transform_response_code(result[:response_code]) : :error
        response_code = result && result[:response_code] ? result[:response_code] : 'error'
        tags = {
          action: 'payment',
          partner: 'sepulsa',
          product: product_type,
          biller_product: @biller_product,
          status: status,
          response_code: response_code
        }
        Observer.histogram(Observer::Metric::PARTNER, duration, tags)
      end

      def get_transaction_by_id(transaction_id, product_type)
        start_time = ::Time.current
        url = "#{Channel::Config::SEPULSA_ENDPOINT}transaction/#{transaction_id}.json"

        response = Channel::Connection::Http.get(url, AUTH)
        result = JSON.parse(response).with_indifferent_access

        log_success('get_transaction', url, { transaction_id: transaction_id }, result)

        result[:data] = result[:data] || {}
        result[:data].merge!(transaction_response(result))
      rescue RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout => e
        status = :timeout

        raise e
      rescue RestClient::Exception => e
        log_error('get_transaction', url, { transaction_id: transaction_id }, e.message)
        raise ::Exceptions::PartnerTransactionNotFound.new
      ensure
        duration      = ::Time.current - start_time
        status      ||= result && result[:response_code] ? transform_response_code(result[:response_code]) : :error
        response_code = result && result[:response_code] ? result[:response_code] : 'error'
        tags = {
          action: 'confirm',
          partner: 'sepulsa',
          product: product_type,
          biller_product: @biller_product,
          status: status,
          response_code: response_code
        }
        Observer.histogram(Observer::Metric::PARTNER, duration, tags)
      end

      def get_transaction_by_order_id(order_id, product_type)
        start_time = ::Time.current

        payload = { order_id: order_id }
        response = Channel::Connection::Http.get(TRANSACTION_URL, AUTH, payload)
        result = JSON.parse(response).with_indifferent_access

        unless result[:list].any?
          log_error('get_by_order_id', TRANSACTION_URL, payload, result)
          raise ::Exceptions::PartnerTransactionNotFound.new
        end

        log_success('get_by_order_id', TRANSACTION_URL, payload, result)

        result[:list][0][:data] = result[:list][0][:data] || {}
        result[:list][0][:data].merge!(transaction_response(result[:list][0]))
      rescue RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout => e
        status = :timeout

        raise e
      ensure
        duration      = ::Time.current - start_time
        status      ||= result && result.dig(:list, 0, :data, :response_code) ? transform_response_code(result.dig(:list, 0, :data, :response_code)) : :error
        response_code = result && result.dig(:list, 0, :data, :response_code) ? result.dig(:list, 0, :data, :response_code) : 'error'
        tags = {
          action: 'confirm',
          partner: 'sepulsa',
          product: product_type,
          biller_product: @biller_product,
          status: status,
          response_code: response_code
        }
        Observer.histogram(Observer::Metric::PARTNER, duration, tags)
      end

      def can_confirm?
        true
      end

      def get_auth
        if Toggles::SepulsaMitraAuth.active? && @object.is_mitra?
          MITRA_AUTH
        else
          AUTH
        end
      end

      private

      def partner_name
        class_name_array = self.class.name.split('::').map { |s| s.underscore }
        class_name_array.second
      end

      def pdam?(product_type)
        product_type == PDAM_PRODUCT
      end

      def is_boolean?(value)
        value.is_a?(TrueClass) || value.is_a?(FalseClass)
      end

      def response_success?(response_code)
        response_code == "00" || response_code == "10"
      end

      def raise_error(response_code)
        case response_code.to_s
        when "20"
          raise ::Exceptions::UnregisteredNumber.new
        when "50"
          raise ::Exceptions::BillAlreadyPaid.new
        else
          raise ::Exceptions::DefaultError.new
        end
      end

      def transform_response_code(response_code)
        response_code = response_code.to_s.rjust(2, "0")

        return :success if SUCCESS_REQUEST_RC_LIST.include? response_code
        return :fail    if FAIL_REQUEST_RC_LIST.include? response_code
        return :pending if PENDING_REQUEST_RC_LIST.include? response_code
        return :error
      end

      def autoswitch_status(response_code)
        response_code = response_code.to_s.rjust(2, "0")

        return :failed if FAIL_PARTNER_REQUEST_RC_LIST.include?(response_code)
        return :success
      end

      def transaction_response(response)
        {
          partner_transaction_id: response[:transaction_id].to_s,
          status: PARTNER_STATUS[SEPULSA][response[:status]]
        }
      end

      def log_success(action, url, payload, response)
        tags = ['partner', action, 'success', 'sepulsa']
        log_request(tags, log_message(url, payload, response))
      end

      def log_error(action, url, payload, response)
        tags = ['partner', action, 'failed', 'sepulsa']
        log_request(tags, log_message(url, payload, response))
      end

      def log_message(url, payload, response)
        {
          url: url,
          payload: payload,
          response: response,
          buyer_id: buyer_id
        }.to_s
      end

      def buyer_id
        @object.buyer_id if @object.respond_to?(:buyer_id)
      end
    end
  end
end
