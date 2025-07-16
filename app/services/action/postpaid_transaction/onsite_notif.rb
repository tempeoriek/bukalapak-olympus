module Action
  module PostpaidTransaction
    class OnsiteNotif
      URL = "#{Channel::Config::TELOLET_URL}/_internal/publishers/onsite".freeze
      AUTH = "Basic #{Channel::Config::TELOLET_AUTH_KEY}".freeze
      include Postpaid::Constant

      def initialize(transaction, status)
        @transaction = transaction
        @status = status
      end

      def run!
        return false unless run?

        payload = {}

        payload[:body] = case @status
          when BUKALAPAK_PROCESSED then get_processed_payload
          when BUKALAPAK_REMIT then get_remit_payload
          when BUKALAPAK_REFUND then get_refund_payload
        end
        payload[:user_id] = @transaction.buyer_id
        payload[:source] = "olympus"
        payload[:queue] = "notification.onsite"
        payload[:version] = "1.0"

        target = payload[:body][:target]
        payload[:body].delete(:target)
        platforms = case target
          when "normal" then ["onsite_web", "onsite_app"]
          when "agent" then ["onsite_agenlite"]
        end

        platforms.each do |platform|
          payload[:onsite_platform] = platform
          Channel::Connection::Http.post(URL, AUTH, payload)
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
