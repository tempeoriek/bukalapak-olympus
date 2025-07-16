module Action
  module BpjsKesehatanTransaction
    class UpdateStatus < Action::PostpaidTransaction::UpdateStatus

      def initialize(transaction, response)
        super(transaction, response)
      end

      def run!
        super
      end

      private

      def update_succeeded_transaction!
        ActiveRecord::Base.transaction do
          @transaction.reference_number = @response.reference_number
          @transaction.info = @response.info
          @transaction.save!
        end
      end
    end
  end
end
