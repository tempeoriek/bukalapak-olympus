module Serializer
  module Internal
    module PdamTransaction
      class Commission
        attr_reader :object

        def initialize(object)
          @object = object
        end

        def as_json(_options = {})
          {
            value: object.value,
            min_transaction_value: object.min_transaction_value,
            max_transaction_value: object.max_transaction_value,
          }
        end
      end
    end
  end
end
