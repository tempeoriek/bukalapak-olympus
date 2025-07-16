module Action
    module PdamOperatorCommissionSetting
      class Update
        def initialize(form)
          @form = form
        end

        def run!
          operator = ::PdamOperator.find(@form.operator_id)
          raise Exceptions::OperatorNotFound.new unless operator.present?

          setting = ::PdamOperatorCommissionSetting.find_by(pdam_operator_id: @form.operator_id)
          raise Exceptions::CommissionSettingNotFound.new unless setting.present?

          setting.update!(
            pdam_operator_id: @form.operator_id,
            value: @form.value,
            state: @form.state,
            min_transaction_value: @form.min_transaction_value,
            max_transaction_value: @form.max_transaction_value
          )

          setting
        end
      end
    end
end

