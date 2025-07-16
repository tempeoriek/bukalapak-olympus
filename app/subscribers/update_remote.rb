module Subscribers
  class UpdateRemote < Base
    private

    def topic_name
      Subscribers::Topics::UPDATE_REMOTE
    end

    def process_task(transaction, options, log_tags)
      if partner_final_states?(transaction)
        Escrow::UpdateTransactionStatus.new(transaction).run!
        Channel::Middleman::Callback.new(transaction).run! if transaction.try(:collecting_agent?)
      else
        raise Exceptions::InvalidStatusError.new("State is `#{transaction.state}`, should be partner_succeeded or partner_failed instead")
      end
    end

    def partner_final_states?(transaction)
      transaction.partner_succeeded? || transaction.partner_failed? || transaction.cancelled?
    end
  end
end
