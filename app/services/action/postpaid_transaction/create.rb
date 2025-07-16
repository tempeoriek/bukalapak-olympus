module Action
  module PostpaidTransaction
    class Create
      include PostpaidTransactionUtility

      def initialize(form, buyer_id, transaction_type = 0, context = nil)
        @form = form
        @buyer_id = buyer_id
        @transaction_type = transaction_type
        @context = context
      end

      private

      def save_transaction!(transaction, expiration_time_in_hour: 10)
        ActiveRecord::Base.transaction do
          if transaction.valid?
            transaction.save!
            register_transaction!(transaction, expiration_time_in_hour: expiration_time_in_hour)
            transaction
          else
            raise Exceptions::CreateTransactionError.new
          end
        end
      end

      def get_inquiry
        # inquiry again
        Action::PostpaidTransaction::Inquiry.new(@form).run!
      end

      def register_transaction!(transaction, expiration_time_in_hour: 10)
        # Action::PostpaidTransaction::Register used to tell bukalapak to create a remote transaction
        response = Escrow::RegisterTransaction.new(transaction, expiration_time_in_hour: expiration_time_in_hour).run!
        transaction.remote_transaction_id = response[:id]
        transaction.save!
      end
    end
  end
end
