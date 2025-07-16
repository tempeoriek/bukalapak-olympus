module Action
  module CreditCardBillTransaction
    class DeleteToken

      def initialize(transaction)
        @transaction = transaction
      end

      def run!
        if @transaction.visa? && partner_channel.respond_to?(:delete_token) && @transaction.token.present?
          token_deleted = partner_channel.delete_token # return true if delete request succeeded
          ActiveRecord::Base.transaction do
            @transaction.token = nil
            @transaction.save!
          end if token_deleted # remove token in db if remote token on cybs has been deleted
        end
      end

      private

      def partner_channel
        @partner_channel ||= Channel.new_partner_channel(@transaction)
      end
    end
  end
end
