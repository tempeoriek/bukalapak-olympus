module Exclusive
    class PdamOperatorCommissionSettingController < ::PostpaidsController
        before_action :authorize!

        def show
            setting = PdamOperatorCommissionSetting.find_by(pdam_operator_id: params[:operator_id])
            raise ::Exceptions::CommissionSettingNotFound.new if setting.nil?

            render_response(serialize(setting), 200)
        end

        def create
            form = Form::PdamOperatorCommissionSetting.new(params)
            setting = Action::PdamOperatorCommissionSetting::Create.new(form).run!
            render_response(serialize(setting), 201)
        end

        def update
            form = Form::PdamOperatorCommissionSetting.new(params)
            setting = Action::PdamOperatorCommissionSetting::Update.new(form).run!
            render_response(serialize(setting), 201)
        end

        private

        def authorize!
            raise ::Exceptions::UnauthorizedUser unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
        end

        def serialize(setting)
            Serializer::Exclusive::PdamOperatorCommissionSetting.new(setting)
        end
    end
end
