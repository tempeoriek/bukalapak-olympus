module Action
  module CreditCardBillTransaction
    class UpdateStatus < Action::PostpaidTransaction::UpdateStatus

      def initialize(transaction, response)
        super(transaction, response)
      end

      def run!
        super
      end

      private

      def update_succeeded_transaction!
        @transaction.customer_name = @response.customer_name unless @response.customer_name.nil?
        @transaction.statement_date = @response.statement_date unless @response.statement_date.nil?
        @transaction.due_date = @response.due_date unless @response.due_date.nil?
        @transaction.minimum_payment = @response.minimum_payment unless @response.minimum_payment.nil?
        
        @transaction.partner_financial_journal_number = @response.partner_financial_journal_number
        @transaction.partner_journal_number = @response.partner_journal_number
        @transaction.response_code = @response.response_code if @transaction.visa?
        @transaction.save!
      end

      def update_transaction_id!
        @transaction.reference_number = @response.reference_number if @transaction.biller.partner.name == 'pnl'
        super
      end
    end
  end
end
