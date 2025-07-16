module Form
  class PdamOperator < Base
    def initialize(params)
      @params = params
    end

    def create_params
      @params.merge(active: state, have_issue: ::Postpaid::Constant::PDAM_NO_ISSUE) unless @params[:active].nil?
    end

    def update_params
      return create_params if @params[:have_issue].nil?

      create_params.merge!(have_issue: have_issue)
    end

    private

    def state
      @params[:active] ? ::Postpaid::Constant::ACTIVE : ::Postpaid::Constant::INACTIVE
    end

    def have_issue
      @params[:have_issue] ? ::Postpaid::Constant::PDAM_HAVE_ISSUE : ::Postpaid::Constant::PDAM_NO_ISSUE
    end
  end
end
