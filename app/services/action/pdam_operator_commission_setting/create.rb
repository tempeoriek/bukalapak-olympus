module Action
    module PdamOperatorCommissionSetting
      class Create
        def initialize(form)
          @form = form
        end

        def run!
          operator = ::PdamOperator.find(@form.operator_id)
          raise Exceptions::OperatorNotFound.new unless operator.present?

          setting = ::PdamOperatorCommissionSetting.new(
                        pdam_operator_id: @form.operator_id,
                        value: @form.value,
                        state: @form.state,
                        max_transaction_value: @form.max_transaction_value,
                        min_transaction_value: @form.min_transaction_value
                    )
          setting.save!
          setting
        end
      end
    end
end

