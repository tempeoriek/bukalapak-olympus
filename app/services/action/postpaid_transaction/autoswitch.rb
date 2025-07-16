module Action
  module PostpaidTransaction
    module Autoswitch
      include PostpaidTransactionUtility

      def record_autoswitch_value(action, status, product_type, options = {})
        mechanism_mapping = {
          ELECTRICITY_PRODUCT => Action::ElectricityAutoswitch::Mechanism::Record,
          PDAM_PRODUCT => Action::PdamAutoswitch::Mechanism::Record
        }

        return unless mechanism_mapping.key?(product_type.to_s)

        arguments = {
          action: action, # ['inquiry', 'refund_rate'] 
          status: status # [:success, :failed]
        }
        arguments[:operator_id] = options[:operator_id] if product_type.to_s == 'pdam'

        action_class = mechanism_mapping[product_type.to_s]
        action_class.new(arguments).run!
      rescue => e
        tags = [product_type, 'autoswitch', 'record']
        log_error("Failed to record autoswitch value #{e}", tags, nil)
      end
    end
  end
end
