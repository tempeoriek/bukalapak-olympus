module Channel
  module Pnl
    class Base
      include PostpaidTransactionUtility
      include ApplicationHelper

      PARTNER_TAG = %w[partner dbs]

      AUTH = 'Basic ' + Channel::Config::BTS_KUBE_AUTH_KEY.freeze
      BASE_URL = Channel::Config::BTS_KUBE_URL.freeze
      INQUIRY_URL = "#{BASE_URL}/_internal/dbs/inquiry".freeze
      PAY_URL = "#{BASE_URL}/_internal/dbs/payment".freeze
      MITRA_PAY_PATH = "/_internal/bts-kube/background-jobs/dbs-transfer".freeze
      MITRA_PAY_URL = "#{BASE_URL}#{MITRA_PAY_PATH}".freeze

      CONFIRM_URL = "#{BASE_URL}/_internal/dbs/inquiry-transaction".freeze
      OLYMPUS_USER = 'olympus'.freeze

      # NOTE: IF we edit this, make sure to edit the one in bts-kube microservice too in dbs transfer service for olympus
      CALLBACK_URL = Channel::Config::BTS_KUBE_CALLBACK_URL.freeze

      CC_NUMBER_KEY_NAMES = [
        :number,
        :customer_number,
        :account_number,
        :account_no
      ].freeze

      def inquiry(customer_number, biller_id)
        start_time = ::Time.current

        url = INQUIRY_URL
        biller = CreditCardBiller.find_by(id: biller_id)
        raise Exceptions::BillerNotFound.new if biller.nil?

        payload = {
          number: customer_number,
          bank: biller.partner.biller_code
        }
        opts = {
          crypto_hash_object_keys: CC_NUMBER_KEY_NAMES
        }
        response = Channel::Connection::Http.post(
          url,
          AUTH,
          payload,
          {},
          opts
        )
        result = JSON.parse(response).deep_symbolize_keys!

        # Validate the result
        begin
          if result[:data][:valid]
            status = :success
          else
            status = :failed
            raise ::Exceptions::BtsKube::InquiryFailed.new("Inkuiri Gagal, #{result[:message]}")
          end
        ensure
          others = { duration: ::Time.current - start_time, http_code: status }
          log_and_metric(status, :inquiry, url, payload, result, others)
        end

        # Return result
        result
      rescue RestClient::Exception => e
        others = { duration: ::Time.current - start_time, http_code: e.http_code.to_s }
        log_and_metric(:error, :inquiry, url, payload, e.response, others)
        raise ::Exceptions::BtsKube::InquiryError.new('Inkuiri Gagal')
      end

      def create(transaction)
        start_time = ::Time.current

        if mitra_create_credential?(transaction)
          url = mitra_pay_url
          payload = mitra_create_payload(transaction)
        else
          url = PAY_URL
          payload = create_payload(transaction)
        end

        opts = {
          crypto_hash_object_keys: CC_NUMBER_KEY_NAMES
        }

        # Make request, will raise error if response code != 200
        response = Channel::Connection::Http.post(
          url,
          AUTH,
          payload,
          {},
          opts
        )
        result = JSON.parse(response).deep_symbolize_keys!

        others = { duration: ::Time.current - start_time, http_code: 'success' }
        log_and_metric(:success, :create, url, payload, result, others)
        result
      rescue RestClient::Exception => e
        others = { duration: ::Time.current - start_time, http_code: e.http_code.to_s }.merge(transaction_log_entry(transaction))
        log_and_metric(:error, :create, url, payload, e.response, others)
        result = e
        raise ::Exceptions::BtsKube::PaymentError.new("Pembayaran Gagal")
      end

      def confirm(transaction)
        start_time = ::Time.current

        url = CONFIRM_URL
        payload = {
          customer_reference: transaction.order_id,
        }

        response = Channel::Connection::Http.post(
          url,
          AUTH,
          payload
        )

        result = JSON.parse(response).deep_symbolize_keys!

        others = { duration: ::Time.current - start_time, http_code: 'success' }
        log_and_metric(:success, :confirm, url, payload, result, others)
        result
      rescue RestClient::Exception => e
        others = { duration: ::Time.current - start_time, http_code: e.http_code.to_s }.merge(transaction_log_entry(transaction))
        log_and_metric(:error, :confirm, url, payload, e.response, others)
        raise ::Exceptions::BtsKube::ConfirmError.new("Confirm Gagal")
      end

      def can_confirm?
        true
      end

      private

      # NOTE: Mitra still use marketplace credential instead of BMI
      def mitra_create_credential?(transaction)
        return false unless Toggles::PnlMitraAuth.active?
        transaction.collecting_agent?
      end

      # force to use non wiremock for mitra & collecting_agent if env is true
      def mitra_pay_url
        return MITRA_PAY_URL unless ENV['PREPROD_FORCE_PNL_NON_WIREMOCK'] == 'true'
        base_url = ENV['BTS_KUBE_NON_WIREMOCK_URL']

        "#{base_url}#{MITRA_PAY_PATH}"
      end

      def create_payload(transaction)
        {
          payments: [{
            id: transaction.order_id,
            amount: transaction.base_amount,
            txn_date: DateTime.now.strftime('%Y-%m-%d'),
            receiver: {
              account_no: transaction.card_number,
              bank: transaction.biller.partner.biller_code,
              name: transaction.customer_name,
            },
            reference_type: :olympus_transferdbs_ccbill,
            reference_id: transaction.id
          }],
          callback_url: CALLBACK_URL,
        }
      end

      def mitra_create_payload(transaction)
        # in bts-kube, for background_job_dbs_transfer, user is in payload instead of taken from @user from basic auth
        {
          id: transaction.order_id,
          remote_type: CREDIT_CARD_BILL_PRODUCT,
          user: OLYMPUS_USER,
          transaction: {
            amount: transaction.base_amount,
            beneficiary_bank_name: transaction.biller.partner.biller_code,
            beneficiary_account_no: transaction.card_number,
            beneficiary_name: transaction.customer_name,
          }
        }
      end

      def transaction_log_entry(transaction)
        {
          track_id: transaction.id,
          remote_transaction_id: transaction.remote_transaction_id,
        }
      end

      def log_and_metric(status, action, url, payload, result, others={})
        CreditCardBillHelper.hash_cc_number_in_object(payload, CC_NUMBER_KEY_NAMES)
        CreditCardBillHelper.hash_cc_number_in_object(result, CC_NUMBER_KEY_NAMES)

        tags = PARTNER_TAG + %W[#{action} #{status}]
        log_entry = {
          url: url,
          payload: payload,
        }
        if status == :error
          log_entry[:cause] = result
          log_error(tags, log_entry, nil, others)
        else
          log_entry[:response] = result
          log_request(tags, log_entry, nil, others)
        end

        duration = others[:duration]
        product_type = CREDIT_CARD_BILL_PRODUCT
        response_code = others[:http_code]

        entries = {
          action: action,
          partner: 'dbs',
          product: product_type,
          biller_product: @biller_product,
          status: status,
          response_code: response_code
        }
        Observer.histogram(Observer::Metric::PARTNER, duration, entries)
      end
    end
  end
end
