module Exclusive::Pdam::Admin::Autoswitch
  class GroupMemberController < ::PostpaidsController
    before_action :authorize!

    PRODUCT_NAME = PDAM_PRODUCT

    def create
      form = Form::Exclusive::Admin::Pdam::Autoswitch::GroupMember::Create.new(params)

      raise ::Exceptions::InvalidParameterError unless form.valid?

      autoswitch_group_member = Action::PdamAutoswitch::GroupMember::Create.new(form.create_params).run!
      render_response(::Serializer::Exclusive::Pdam::Admin::AutoswitchGroupMember.new(autoswitch_group_member), 201)
    end

    def delete
      form = Form::Exclusive::Admin::Pdam::Autoswitch::GroupMember::Delete.new(params)

      raise ::Exceptions::InvalidParameterError unless form.valid?

      Action::PdamAutoswitch::GroupMember::Delete.new(form.delete_params).run!

      render json: {message: 'Autoswitch Group Members successfully deleted', meta: {http_status: 200}}, status: 200
    end

    def status
      form = Form::Exclusive::Admin::Pdam::Autoswitch::GroupMember::Status.new(params)

      raise ::Exceptions::InvalidParameterError unless form.valid?

      autoswitch_group_member = Action::PdamAutoswitch::GroupMember::Status.new(form.status_params).run!
      render_response(::Serializer::Exclusive::Pdam::Admin::AutoswitchGroupMember.new(autoswitch_group_member), 200)
    end

    private

    def authorize!
      raise ::Exceptions::UnauthorizedUser.new unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
    end
  end
end
