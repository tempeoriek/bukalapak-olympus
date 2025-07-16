module Action
  module PdamTransaction
    class CalculateCommission
      def initialize(transaction)
        @transaction = transaction
      end

      def run!
        settings = ::PdamOperatorCommissionSetting.where(pdam_operator_id: @transaction.pdam_operator_id).order(:id).all

        # If there are no such settings, return 0.
        selected = ::PdamOperatorCommissionSetting.new(value: 0, min_transaction_value: 0, max_transaction_value: 100_000_000, state: 'active')
        settings.each do |setting|
          selected = setting if setting.state == 'active' && amount.between?(setting.min_transaction_value, setting.max_transaction_value)
        end

        selected
      end

      def amount
        @transaction.amount
      end
    end
  end
end
