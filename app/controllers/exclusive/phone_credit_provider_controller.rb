module Exclusive
  class PhoneCreditProviderController < ::PostpaidsController

    before_action :authorize!

    PRODUCT_NAME = PHONE_CREDIT_PRODUCT

    def list
      result = []
      PhoneCreditProvider.not_deleted.each do |provider|
        result << serialize(provider)
      end
      render_response(result, 200)
    end

    def show
      provider = PhoneCreditProvider.not_deleted.find(params[:id])
      render_response(serialize(provider), 200)
    end

    def update
      params = JSON.parse(request.body.read).with_indifferent_access
      params['provider'] = params['name']
      params.delete('name')
      form = Form::PhoneCreditProvider.new(params)
      provider = PhoneCreditProvider.not_deleted.find(params[:id])
      provider.update_attributes!(form.update_params)
      render_response(serialize(provider), 200)
    end

    private

    def authorize!
      raise ::Exceptions::UnauthorizedUser.new unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
    end

    def serialize(provider)
      Serializer::Exclusive::PhoneCreditProvider.new(provider)
    end
  end
end
