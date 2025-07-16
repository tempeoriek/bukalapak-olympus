module Recurrence
  module Postpaid
    class Notifier
      include PostpaidTransactionUtility

      TELOLET_PUSH_NOTIF_URL = "#{Channel::Config::TELOLET_URL}/_internal/publishers/push-notifications".freeze
      TELOLET_ONSITE_NOTIF_URL = "#{Channel::Config::TELOLET_URL}/_internal/publishers/onsite".freeze
      TELOLET_AUTH = "Basic #{Channel::Config::TELOLET_AUTH_KEY}".freeze

      def initialize(template, template_detail_id)
        @template = template
        @template_detail_id = template_detail_id
      end

      def run!
        if @template =~ BALANCE_NOTIFER_TEMPLATE
          send_balance_push_notif(get_buyer_id)
          send_balance_onsite_notif(get_buyer_id)
          payload = notify_balance_payload
        elsif @template =~ STOP_NOTIFIER_TEMPLATE
          payload = notify_stop_payload
        elsif @template =~ SUBSCRIBE_SUCCESS_NOTIFIER_TEMPLATE
          payload = notify_success_subscribe_payload
        elsif @template =~ SUCCESS_TRANSACTION_NOTIFIER_TEMPLATE
          payload = notify_success_transaction_payload
        elsif @template =~ ERROR_TRANSACTION_NOTIFIER_TEMPLATE
          payload = notify_error_transaction_payload
        else
          raise 'unsupported notification template'
        end

        EmailNotif.new(@template, get_buyer_id, payload).run!

        log_request(%W(#{postpaid_product} recurrence notification success), generate_log_message, template_detail.id)
      rescue => e # log the error
        log_request(%W(#{postpaid_product} recurrence notification failed), generate_error_log_message(e))
        Honeybadger.notify(e)
        raise
      end

      private

      def send_balance_onsite_notif(buyer_id)
        payload = {}
        payload = get_balance_onsite_notif_payload(buyer_id)
        payload[:source] = "olympus"
        payload[:version] = "1.0"
        payload[:queue] = "notification.onsite"
        onsite_notif_platforms.each do |platform|
          payload[:onsite_platform] = platform
          Channel::Connection::Http.post(TELOLET_ONSITE_NOTIF_URL, TELOLET_AUTH, payload)
        end
      end

      def send_balance_push_notif(buyer_id)
        payload = {}
        payload[:data] = get_balance_push_notif_payload(buyer_id)
        payload[:source] = "olympus"
        payload[:version] = "1.0"
        payload[:queue] = "notification.push_notification"
        push_notif_platforms.each do |platform|
          payload[:data][:platform] = platform
          Channel::Connection::Http.post(TELOLET_PUSH_NOTIF_URL, TELOLET_AUTH, payload)
        end
      end

      def generate_error_log_message(e)
        log_message = generate_log_message
        log_message[:error] = {
          message: e&.message,
          backtrace: e&.backtrace.take(7).join("\n")
        }
        log_message
      end

      def notify_balance_payload
        raise NotImplementedError
      end

      def notify_stop_payload
        raise NotImplementedError
      end

      def notify_success_subscribe_payload
        raise NotImplementedError
      end

      def notify_success_transaction_payload
        raise NotImplementedError
      end

      def notify_error_transaction_payload
        raise NotImplementedError
      end

      def template_detail
        raise NotImplementedError
      end

      def postpaid_product
        raise NotImplementedError
      end

      def generate_log_message
        raise NotImplementedError
      end

      def get_balance_onsite_notif_payload(buyer_id)
        raise NotImplementedError
      end

      def get_balance_push_notif_payload(buyer_id)
        raise NotImplementedError
      end

      def get_buyer_id
        raise NotImplementedError
      end

      def onsite_notif_platforms
        ["onsite_web", "onsite_app"]
      end

      def push_notif_platforms
        ['android', 'ios', 'chromeweb', 'firefox', 'safari']
      end
    end
  end
end
