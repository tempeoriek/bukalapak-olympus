module Exclusive
  class CreditCardBillerController < ApplicationController
    include Postpaid::Constant
    include Response
    include Authenticate

    before_action :authorize!

    PRODUCT_NAME = CREDIT_CARD_BILL_PRODUCT

    def list
      result = []
      CreditCardBiller.not_deleted.each do |biller|
        result << serialize(biller)
      end
      render_response(result, 200)
    end

    def show
      biller = CreditCardBiller.not_deleted.find_by_id(params[:id])
      raise Exceptions::BillerNotFound.new unless biller.present?
      render_response(serialize(biller), 200)
    end

    def create
      params = JSON.parse(request.body.read).with_indifferent_access
      form = Form::CreditCardBiller.new(params)
      biller = Action::CreditCardBiller::Create.new(form.create_params).run!
      render_response(serialize(biller), 201)
    end

    def update
      id = params[:id]
      params = JSON.parse(request.body.read).with_indifferent_access
      form = Form::CreditCardBiller.new(params)
      biller = CreditCardBiller.not_deleted.find(id)
      biller.update_attributes!(form.update_params)
      render_response(serialize(biller), 200)
    end

    def delete
      biller = CreditCardBiller.not_deleted.find(params[:id])
      transaction = CreditCardBillTransaction.find_by(credit_card_biller_id: params[:id])
      raise Exceptions::CannotDeleteOperator.new if transaction
      biller.update_attributes!({active: -1})
      render json: {message: "Biller successfully deleted", meta: {http_status: 202}}, status: 202
    end

    def show_biller_partners
      result = []
      partners = CreditCardBillPartner.where('credit_card_biller_id = ? AND NOT state = -1', params[:id])
      partners.each do |partner|
        result << Serializer::Exclusive::CreditCardBillPartner.new(partner)
      end
      render_response(result, 200)
    end

    def show_partners
      result = { names: [
        BNI,
        PNL
      ]}
      render_response(result, 200)
    end

    private

    def authorize!
      raise ::Exceptions::UnauthorizedUser.new unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
    end

    def serialize(biller)
      Serializer::Exclusive::CreditCardBiller.new(biller)
    end
  end
end
