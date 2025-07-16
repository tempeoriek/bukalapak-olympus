module Internal
  class PdamController < Internal::PostpaidController
    include Response
    include Authenticate
    include PdamAutoswitchHelper

    PRODUCT_NAME = PDAM_PRODUCT
    COLLECTING_AGENT_BL_SERVICES = %w[middleman]

    def inquiries
      return unless http_basic_authenticate == true

      operator = select_active_operator_by_group_id(params[:autoswitch_group_id])

      raise ::Exceptions::InvalidPdamOperator.new if operator.nil?

      form = Form::Pdam.new(params[:customer_number], operator.id, 'NO_USERNAME', determine_buyer_type_by_bl_service)

      raise ::Exceptions::InvalidParameterError.new unless form.valid?

      action = Action::PostpaidTransaction::Inquiry.new(form)
      result = action.run!
      render_response(pdam_inquiry_format(result), 200)
    end

    def create
      return unless http_basic_authenticate == true

      operator = select_active_operator_by_group_id(params[:autoswitch_group_id])
      raise ::Exceptions::InvalidPdamOperator.new if operator.nil?

      buyer_id = params[:buyer_id]

      form = Form::Pdam.new(params[:customer_number], operator.id, 'NO_USERNAME', determine_buyer_type_by_bl_service)

      action = Action::PdamTransaction::Create.new(form, buyer_id, determine_buyer_type_by_bl_service)
      transaction = action.run!

      render_response(::Serializer::Internal::PdamTransaction::Create.new(transaction).as_json, 201)
    end

    def show
      # basic authentication for mothership
      authenticated = http_basic_authenticate
      # this is to avoiding double render
      return unless authenticated == true

      transaction = PdamTransaction.find_by_id(params[:id])
      raise Exceptions::TransactionNotFound.new unless transaction.present?

      render_response(transaction.as_json, 200)
    end

    def status
      super {
        |id|
          PdamTransaction.find_by_id(id)
      }
    end

    def commission
      # basic authentication for mothership
      authenticated = http_basic_authenticate
      # this is to avoiding double render
      return unless authenticated == true

      transaction = PdamTransaction.find_by_id(params[:id])
      raise Exceptions::TransactionNotFound.new unless transaction.present?

      commission = Action::PdamTransaction::CalculateCommission.new(transaction).run!
      raise Exceptions::CommissionNotFound.new unless commission.present?

      render_response(::Serializer::Internal::PdamTransaction::Commission.new(commission).as_json, 200)
    end

    private

    def determine_buyer_type_by_bl_service
      if COLLECTING_AGENT_BL_SERVICES.include? request_bl_service
        COLLECTING_AGENT_BUYER_TYPE
      else
        NORMAL_BUYER_TYPE
      end
    end
  end
end
