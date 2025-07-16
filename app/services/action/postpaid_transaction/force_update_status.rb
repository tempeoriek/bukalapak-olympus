module Action
  module PostpaidTransaction
    class ForceUpdateStatus
      include PostpaidTransactionUtility

      def initialize(transaction, status)
        @transaction = transaction
        @status = status
      end

      def run!
        case @status
        when 'failed'
          if @transaction.pending?
            @transaction.expire!
          else
            @transaction.force_fail!
          end
        when 'succeed'
          @transaction.force_success!
        when 'expired'
          @transaction.expire!
        else
          raise Exceptions::InvalidStatusError.new("It's not possible to change from #{@transaction.state} to #{@status}")
        end

        Channel::Middleman::Callback.new(@transaction).run! if @transaction.try(:collecting_agent?)
        Action::PostpaidTransaction::SendNotification.new(@transaction).run! unless @transaction.expired?

        @transaction
      end
    end
  end
end
