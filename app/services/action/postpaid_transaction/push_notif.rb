module Action
  module PostpaidTransaction
    class PushNotif
      URL = "#{Channel::Config::TELOLET_URL}/_internal/publishers/push-notifications".freeze
      AUTH = "Basic #{Channel::Config::TELOLET_AUTH_KEY}".freeze
      include ApplicationHelper
      include Postpaid::Constant

      def initialize(transaction, status)
        @transaction = transaction
        @status = status
      end

      def run!
        return false unless run?
        payload = {}
        payload[:data] = case @status
          when BUKALAPAK_PROCESSED then get_processed_payload
          when BUKALAPAK_REMIT then get_remit_payload
          when BUKALAPAK_REFUND then get_refund_payload
        end
        payload[:data][:user_id] = @transaction.buyer_id
        payload[:source] = "olympus"
        payload[:queue] = "notification.push_notification"
        payload[:version] = "1.0"

        platforms = case payload[:data][:target]
          when "normal" then ['android', 'ios', 'chromeweb', 'firefox', 'safari']
          when "agent" then ['mitra_android', 'mitra_pwa']
        end

        payload[:data].delete(:target) # refactor after removing target from get_payload

        platforms.each do |platform|
          payload[:data][:platform] = platform
          Channel::Connection::Http.post(URL, AUTH, payload) # TODO: probably should not use channel
        end
      end

      private

      def run?
        @transaction && [BUKALAPAK_PROCESSED, BUKALAPAK_REMIT, BUKALAPAK_REFUND].include?(@status)
      end

      def get_processed_payload
        raise NotImplementedError
      end

      def get_remit_payload
        raise NotImplementedError
      end

      def get_refund_payload
        raise NotImplementedError
      end
    end
  end
end
