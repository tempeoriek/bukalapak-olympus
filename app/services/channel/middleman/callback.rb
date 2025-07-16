module Channel
  module Middleman
    class Callback
      include PostpaidTransactionUtility
      include ApplicationHelper

      AUTH   = 'Basic ' + Channel::Config::MIDDLEMAN_AUTH_KEY.freeze
      URL    = "#{Channel::Config::MIDDLEMAN_ENDPOINT}/_internal/collecting-agents/transactions/callback".freeze
      HEADER = {
        'BL-Service': 'olympus'
      }

      def initialize(transaction)
        @transaction = transaction
      end

      def run!
        start_time = ::Time.current
        payload = build_payload(@transaction)
        response = Channel::Connection::Http.post(URL, AUTH, payload, HEADER)
        result = JSON.parse(response).with_indifferent_access

        log_success('middleman_callback', URL, payload, result)
      rescue => e
        error_response_code = e&.response&.code
      ensure
        duration      = ::Time.current - start_time

        response_code = result&.dig("meta", "http_status") || error_response_code
        status        = response_code == 200 ? :success : :error
        tags = {
          action: 'callback',
          partner: 'middleman',
          product: @transaction.product_type,
          status: status,
          response_code: response_code
        }
        Observer.histogram(Observer::Metric::PARTNER, duration, tags)
      end

      def can_confirm?
        false
      end

      private

      def build_payload(transaction)
        payload = {
          id: transaction.id,
          status: transaction.middleman_state,
          response_code: credit_card_bill? ? transaction.middleman_response_code : transaction.response_code,
          failed_reason: credit_card_bill? ? transaction.middleman_failed_reason : transaction.failed_reason,
          type: transaction.product_type,
        }

        payload[:details] = transaction.middleman_details if transaction.respond_to?(:middleman_details)
        payload
      end

      def log_success(action, url, payload, response)
        tags = ['partner', action, 'success', 'middleman']
        log_request(tags, log_message(url, payload, response))
      end

      def log_message(url, payload, response)
        {
          url: url,
          payload: payload,
          response: response,
        }.to_s
      end

      def credit_card_bill?
        @transaction.is_a?(CreditCardBillTransaction)
      end
    end
  end
end
