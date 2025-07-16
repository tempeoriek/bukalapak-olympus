module Subscribers
  class SievexPredict < Base
    private

    def topic_name
      Subscribers::Topics::SIEVEX_PREDICT
    end

    def process_task(transaction, options, log_tags)
      Action::PostpaidTransaction::SievexPredict.new(transaction).run!
    end
  end
end
