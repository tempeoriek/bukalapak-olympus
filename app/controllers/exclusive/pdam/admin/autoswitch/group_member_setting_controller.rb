module Exclusive::Pdam::Admin::Autoswitch
  class GroupMemberSettingController < ::PostpaidsController
    before_action :authorize!

    PRODUCT_NAME = PDAM_PRODUCT

    def index
      autoswitch_group_member_settings = Action::PdamAutoswitch::GroupMemberSetting::List.new(params).run!
      result = serialize_list(autoswitch_group_member_settings, ::Serializer::Exclusive::Pdam::Admin::AutoswitchGroupMemberSetting)
      render_response(result, 200)
    end

    def create
      form = Form::Exclusive::Admin::Pdam::Autoswitch::GroupMemberSetting::Create.new(params)

      raise ::Exceptions::InvalidParameterError unless form.valid?

      autoswitch_group_member_setting = Action::PdamAutoswitch::GroupMemberSetting::Create.new(form.create_params).run!
      render_response(::Serializer::Exclusive::Pdam::Admin::AutoswitchGroupMemberSetting.new(autoswitch_group_member_setting), 201)
    end

    def update
      form = Form::Exclusive::Admin::Pdam::Autoswitch::GroupMemberSetting::Update.new(params)

      raise ::Exceptions::InvalidParameterError unless form.valid?

      autoswitch_group_member_setting = Action::PdamAutoswitch::GroupMemberSetting::Update.new(form.update_params).run!
      render_response(::Serializer::Exclusive::Pdam::Admin::AutoswitchGroupMemberSetting.new(autoswitch_group_member_setting), 200)
    end

    private

    def authorize!
      raise ::Exceptions::UnauthorizedUser.new unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
    end

    def serialize_list(instances, serializer)
      instances.map do | instance | serializer.new(instance) end
    end
  end
end
