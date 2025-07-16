module Form
  class CreditCardBiller < Base
    def initialize(params)
      @params = params
    end

    def create_params
      @params.merge!({
        active: state,
      })
    end

    def update_params
      @params.merge!({
        active: state,
      })
    end

    private

    def state
      @params[:active] ? ::Postpaid::Constant::ACTIVE : ::Postpaid::Constant::INACTIVE
    end
  end
end
