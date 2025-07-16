module Serializer
    module Exclusive
        class PdamOperatorCommissionSetting
            def initialize(setting)
                @setting = setting
            end

            def as_json(_options = {})
                {
                    operator_id: @setting.pdam_operator_id,
                    value: @setting.value,
                    state: @setting.state,
                    min_transaction_value: @setting.min_transaction_value,
                    max_transaction_value: @setting.max_transaction_value
                }
            end
        end
    end
end

