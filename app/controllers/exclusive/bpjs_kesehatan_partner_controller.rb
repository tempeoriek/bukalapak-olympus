module Exclusive
  class BpjsKesehatanPartnerController < ::PostpaidsController

    before_action :authorize!

    PRODUCT_NAME = BPJS_KESEHATAN_PRODUCT

    def list
      result = []
      BpjsKesehatanPartner.all.each do |partner|
        result << serialize(partner)
      end
      render_response(result, 200)
    rescue Exceptions::PostpaidError => e
      render_error(e)
    end

    def show
      partner = BpjsKesehatanPartner.find(params[:id])
      render_response(serialize(partner), 200)
    rescue Exceptions::PostpaidError => e
      render_error(e)
    end

    def update
      params = JSON.parse(request.body.read).with_indifferent_access
      form = Form::BpjsKesehatanPartner.new(params)
      partner = BpjsKesehatanPartner.find(params[:id])

      is_switch = partner.state != params[:state]
      ActiveRecord::Base.transaction do
        partner.update_attributes!(form.update_params)

        deactive_others! if is_switch
      end

      render_response(serialize(partner), 200)
    rescue Exceptions::PostpaidError => e
      render_error(e)
    end

    private

    def authorize!
      token = get_token(request.env['HTTP_AUTHORIZATION'])
      decoded_token = JsonWebToken.decode(token)
      raise ::Exceptions::UnauthorizedUser.new unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
    end

    def serialize(partner)
      Serializer::Exclusive::BpjsKesehatanPartner.new(partner)
    end

    def deactive_others!
      BpjsKesehatanPartner.all.each do |partner|
        next if partner.id == params[:id]
        partner.update!(state: "inactive")
      end
    end
  end
end
