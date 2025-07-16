module Action
  module PostpaidTransaction
    class SievexPredict
      include PostpaidTransactionUtility

      def initialize(transaction)
        @transaction = transaction
      end

      def run!
        raise ::Exceptions::InvalidStatusError.new("state is #{@transaction.state}. should be paid instead") unless @transaction.paid?

        @response = Sievex::Predict.new(@transaction).run!
        count_sievex_metric

        if !Toggles::OlympusSievexAction.active? || ok_to_proceed?(@response[:suggestion])
          publish_create_job
        else
          force_cancel_transaction
        end

      rescue => e
        message = "#{e.class}: #{e.message}"
        LogBook.error(message, tags, track_id: @transaction.remote_transaction_id)
        raise e # so pubsub will catch error and retry
      end

      private

      def ok_to_proceed?(suggestion)
        hash_of_truth = {
          'NORMAL' => true,
          'TRUSTED' => true
        }
        !hash_of_truth[suggestion].blank?
      end

      # Force cancel state to transaction and refund to remote transaction
      def force_cancel_transaction
        @transaction.cancel!
        @transaction.reload

        sievex_action_log = SievexActionLog.new(
          entity_id: @transaction.remote_transaction_id,
          entity_type: ::Sievex::Base::CREDIT_CARD_BILL_ENTITY,
          actor: 'system',
          reason: reason
        )
        sievex_action_log.save!

        Action::PostpaidTransaction::UpdateRemote.new(@transaction).run!
        Action::PostpaidTransaction::SendNotification.new(@transaction).run!
      end

      def publish_create_job
        payload = {
          remote_id: @transaction.remote_transaction_id,
          product_type: @transaction.product_type
        }
        topic_name = is_cc_bill_product(@transaction.product_type) ? Subscribers::Topics::PARTNER_PROCESS_CREDIT_CARD_BILL : Subscribers::Topics::PARTNER_PROCESS
        GcpsPublisher.publish(topic_name, payload, track_id: payload[:remote_id])
      end

      def count_sievex_metric
        opts = {
          product_type: @transaction.product_type,
          suggestion: @response[:suggestion],
          reason: reason
        }
        Observer.counter(Observer::Metric::SIEVEX, 1, opts)
        LogBook.info(@response, tags, track_id: @transaction.remote_transaction_id)
      end

      def reason
        @reason ||= begin
          cats = []
          @response[:categories].each do |cat|
            cat.deep_symbolize_keys!
            cats << cat[:name]
          end
          cats.join(':')
        end
      end

      def is_cc_bill_product(product_type)
        product_type == CREDIT_CARD_BILL_PRODUCT
      end

      def tags
        @tags ||= self.class.name.split('::').map { |s| s.underscore }
      end
    end
  end
end
