module Exclusive::Pdam::Admin::Autoswitch
  class GroupController < ::PostpaidsController
    before_action :authorize!

    PRODUCT_NAME = PDAM_PRODUCT

    def index
      form = Form::Exclusive::Admin::Pdam::Autoswitch::Group::List.new(params)

      raise ::Exceptions::InvalidParameterError unless form.valid?

      autoswitch_groups = Action::PdamAutoswitch::Group::List.new(form.list_params).run!
      rendered_autoswitch_groups = autoswitch_groups.limit(form.list_params[:limit]).offset(form.list_params[:offset])
      result = serialize_list(rendered_autoswitch_groups, ::Serializer::Exclusive::Pdam::Admin::AutoswitchGroup)
      render_response_with_paginantion(result, 200, {http_status: 200, limit: form.list_params[:limit], offset: form.list_params[:offset], total: autoswitch_groups.except(:order, :limit, :offset).count})
    end

    def show
      form = Form::Exclusive::Admin::Pdam::Autoswitch::Group::Show.new(params)

      raise ::Exceptions::InvalidParameterError unless form.valid?

      autoswitch_group = Action::PdamAutoswitch::Group::Show.new(form.show_params).run!
      render_response(::Serializer::Exclusive::Pdam::Admin::AutoswitchGroup.new(autoswitch_group), 200)
    end

    def create
      form = Form::Exclusive::Admin::Pdam::Autoswitch::Group::Create.new(params)

      raise ::Exceptions::InvalidParameterError unless form.valid?

      autoswitch_group = Action::PdamAutoswitch::Group::Create.new(form.create_params).run!
      render_response(::Serializer::Exclusive::Pdam::Admin::AutoswitchGroup.new(autoswitch_group), 201)
    end

    def delete
      form = Form::Exclusive::Admin::Pdam::Autoswitch::Group::Delete.new(params)

      raise ::Exceptions::InvalidParameterError unless form.valid?

      autoswitch_group = Action::PdamAutoswitch::Group::Delete.new(form.delete_params).run!

      render json: {message: 'Autoswitch Group successfully deleted', meta: {http_status: 200}}, status: 200
    end

    def update
      form = Form::Exclusive::Admin::Pdam::Autoswitch::Group::Update.new(params)

      raise ::Exceptions::InvalidParameterError unless form.valid?

      autoswitch_group = Action::PdamAutoswitch::Group::Update.new(form.update_params).run!
      render_response(::Serializer::Exclusive::Pdam::Admin::AutoswitchGroup.new(autoswitch_group), 200)
    end

    def status
      form = Form::Exclusive::Admin::Pdam::Autoswitch::Group::Status.new(params)

      raise ::Exceptions::InvalidParameterError unless form.valid?

      autoswitch_group = Action::PdamAutoswitch::Group::Status.new(form.status_params).run!
      render_response(::Serializer::Exclusive::Pdam::Admin::AutoswitchGroup.new(autoswitch_group), 200)
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
