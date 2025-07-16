module Form::Exclusive::Admin::Pdam::Autoswitch::Group
  class Show
    ATTRIBUTES = Set.new(%i[
        id
    ])

    def initialize(params)
      @params = params
    end

    def show_params
      {
        id: @params[:id]
      }
    end

    def valid?
      !@params[:id].blank?
    end
  end
end
