module Form::Exclusive::Admin::Pdam::Autoswitch::Group
  class Status
    ATTRIBUTES = Set.new(%i[
      id
      state
    ])

    def initialize(params)
      @params = params
    end

    def status_params
      {
        id: @params[:id],
        state: @params[:state]
      }
    end

    def valid?
      !@params[:state].blank? && !@params[:id].blank?
    end
  end
end
