module Exclusive
  class PdamOperatorController < ::PostpaidsController
    before_action :authorize!

    PRODUCT_NAME = PDAM_PRODUCT

    def list
      result = []
      PdamOperator.not_deleted.each do |operator|
        result << serialize(operator)
      end
      render_response(result, 200)
    end

    def show
      operator = PdamOperator.not_deleted.find(params[:id])
      render_response(serialize(operator), 200)
    end

    def create
      params = JSON.parse(request.body.read).with_indifferent_access
      form = Form::PdamOperator.new(params)
      operator = Action::PdamOperator::Create.new(form.create_params).run!
      render_response(serialize(operator), 201)
    end

    def update
      params = JSON.parse(request.body.read).with_indifferent_access
      form = Form::PdamOperator.new(params)
      operator = PdamOperator.not_deleted.find(params[:id])
      operator.update_attributes!(form.update_params)
      render_response(serialize(operator), 200)
    end

    def delete
      operator = PdamOperator.not_deleted.find(params[:id])
      transaction = PdamTransaction.find_by(pdam_operator_id: params[:id])
      raise Exceptions::CannotDeleteOperator if transaction

      operator.update_attributes!({ active: -1 })
      render json: { message: 'Operator successfully deleted', meta: { http_status: 202 } }, status: 202
    end

    private

    def authorize!
      raise ::Exceptions::UnauthorizedUser unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
    end

    def serialize(operator)
      Serializer::Exclusive::PdamOperator.new(operator)
    end
  end
end
