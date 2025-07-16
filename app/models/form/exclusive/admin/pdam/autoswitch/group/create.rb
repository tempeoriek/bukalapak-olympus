module Form::Exclusive::Admin::Pdam::Autoswitch::Group
  class Create
    ATTRIBUTES = Set.new(%i[
        name
        state
    ])

    def initialize(params)
      @params = params
    end

    def create_params
      {
        name: @params[:name],
        state: @params[:state]
      }
    end

    def valid?
      !@params[:name].blank? && !@params[:state].blank?
    end
  end
end
