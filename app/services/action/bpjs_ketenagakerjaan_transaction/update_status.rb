module Action
  module BpjsKetenagakerjaanTransaction
    class UpdateStatus < Action::PostpaidTransaction::UpdateStatus

      def initialize(transaction, response)
        super(transaction, response)
      end

      def run!
        super
      end

      private

      def update_succeeded_transaction!
        @transaction.info = @response.info
        @transaction.reference_number = @response.reference_number
        @transaction.save!
      end
    end
  end
end