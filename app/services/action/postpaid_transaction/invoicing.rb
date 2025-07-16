module Action
  module PostpaidTransaction
    class Invoicing
      include PostpaidTransactionUtility

      def initialize(transaction, invoice_id)
        @transaction = transaction
        @invoice_id = invoice_id
      end

      def run!
        ActiveRecord::Base.transaction do
          @transaction.invoice_id = @invoice_id
          if @transaction.valid?
            @transaction.save!
            @transaction
          else
            raise Exceptions::CreateTransactionError.new
          end
        end
      end
    end
  end
end
