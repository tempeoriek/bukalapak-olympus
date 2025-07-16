module Exclusive
  class CreditCardBillPartnerController < ApplicationController
    include Postpaid::Constant
    include Response
    include Authenticate

    before_action :authorize!, :sanitize_params

    PRODUCT_NAME = CREDIT_CARD_BILL_PRODUCT

    def show_biller_partners
      result = []
      partners = CreditCardBillPartner.where('credit_card_biller_id = ? AND NOT state = -1', params[:id])
      partners.each do |partner|
        result << serialize(partner)
      end
      render_response(result, 200)
    end

    def show_partners
      result = { names: [
        BNI,
        PNL,
        VISA
      ]}
      render_response(result, 200)
    end

    def create
      form = Form::CreditCardBillPartner.new(params) # TODO_CC: partner form
      partner = Action::CreditCardBillPartner::Create.new(form.create_params).run!

      render_response(serialize(partner), 201)
    end

    def update
      id = params[:id]

      form = Form::CreditCardBillPartner.new(params)
      partner = CreditCardBillPartner.not_deleted.find_by_id(id)
      raise Exceptions::PartnerNotFound unless partner
      partner = Action::CreditCardBillPartner::Update.new(form.update_params, partner).run!

      render_response(serialize(partner), 200)
    end

    def delete
      partner = CreditCardBillPartner.not_deleted.find_by_id(params[:id])
      raise Exceptions::PartnerNotFound unless partner

      transaction = CreditCardBillTransaction.find_by(credit_card_bill_partner_id: params[:id])
      raise Exceptions::CannotDeleteOperator.new if transaction

      partner.update_attributes!({state: -1})
      render json: {message: "Partner successfully deleted", meta: {http_status: 202}}, status: 202
    end

    private

    def authorize!
      raise ::Exceptions::UnauthorizedUser.new unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
    end

    def serialize(partner)
      Serializer::Exclusive::CreditCardBillPartner.new(partner)
    end

    def sanitize_params
      params[:id] = params[:id].to_i if params[:id]
      params[:biller_id] = params[:biller_id].to_i if params[:biller_id]
    end

  end
end
