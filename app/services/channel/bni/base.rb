module Channel
  module BNI
    class Base
      include PostpaidTransactionUtility

      # todo: make a generalization of every partner's config
      # todo: define this URL

      BNI_TRANSCTION_LIST_FEATURE_ID = "FTR327".freeze
      BNI_TRANSACTION_DETAIL_FEATURE_ID = "FTR324".freeze

      XAUTH = Channel::Config::BNI_XAUTH_KEY.freeze
      BASIC_AUTH = 'Basic ' + Channel::Config::BNI_BASIC_AUTH_KEY.freeze
      ACCESS_TOKEN_URL = "#{Channel::Config::BNI_ENDPOINT}/api/oauth/token".freeze
      TRANSACTION_URL = "#{Channel::Config::BNI_ENDPOINT}/keagenan/transaction".freeze
      BNI_ACCESS_TOKEN_KEY = "bni_access_token".freeze
      DEALER_ID = Channel::Config::BNI_DEALER_ID.freeze
      KODE_MITRA = Channel::Config::BNI_KODE_MITRA.freeze
      KODE_LOKET = Channel::Config::BNI_KODE_LOKET.freeze
      KODE_CABANG = Channel::Config::BNI_KODE_CABANG.freeze
      PIN_TRANSAKSI = Channel::Config::BNI_PIN_TRANSAKSI.freeze
      ACCOUNT_NUM = Channel::Config::BNI_ACCOUNT_NUM.freeze
      BNI_BILLER_CODE = Channel::Config::BNI_BILLER_CODE.freeze

      def get_token
        token = Keystore.get(BNI_ACCESS_TOKEN_KEY)
        return token if token

        payload = {
          grant_type: "client_credentials"
        }
        headers = {
          content_type: 'application/x-www-form-urlencoded'
        }
        response = Channel::Connection::Http.post(ACCESS_TOKEN_URL, BASIC_AUTH, payload, headers)
        result = JSON.parse(response).with_indifferent_access

        Keystore.set(BNI_ACCESS_TOKEN_KEY, result[:access_token], result[:expires_in])
        result[:access_token]
      end

      def can_confirm?
        false
      end

      private

      def transaction_url
        query = {
          access_token: get_token
        }
        "#{TRANSACTION_URL}?#{query.to_query}"
      end

      def make_request
        @start_time = ::Time.now

        JSON.parse(::Channel::Connection::Http.post(transaction_url, XAUTH, @payload, {'X-Auth': XAUTH})).with_indifferent_access
      end

      def raise_error(response_code)
        case response_code.to_s
        when "14"
          raise ::Exceptions::UnregisteredNumber.new
        when "5005", "5006"
          raise ::Exceptions::BillAlreadyPaid.new
        else
          raise ::Exceptions::DefaultError.new
        end
      end

      def log_message(url, payload, response)
        duration = @start_time ? (::Time.now - @start_time).round(2) : -1
        CreditCardBillHelper.hash_cc_number_in_object(payload[:data], [:cardNum])
        {
          url: url,
          duration: duration,
          payload: payload,
          response: response
        }.to_s
      end

      def log_and_metric(&block)
        action, response, response_code, status = block.call

        tags = ['credit_card_bill', action, status.to_s, 'bni']
        message = log_message(transaction_url, @payload, response)
        log_request(tags, message, @track_id)
      end

      def check_error(data)
        header = {
          host: Channel::Config::ALERT_BOT_HOST
        }
        Channel::Connection::Http.get(Channel::Config::ALERT_BOT_URL, nil, nil, header) if data[:errorNum]&.to_s == "51"
      end

    end
  end
end
