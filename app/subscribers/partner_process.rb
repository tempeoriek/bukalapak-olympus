module Subscribers
  class PartnerProcess < Base
    private

    def topic_name
      Subscribers::Topics::PARTNER_PROCESS
    end

    def process_task(transaction, options, log_tags)
      Action::PostpaidTransaction::PartnerCreate.new(transaction, options).run!
    end
  end
end
