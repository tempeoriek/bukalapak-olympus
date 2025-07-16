module Form::Exclusive::Admin::Pdam::Autoswitch::Group
  class Update
    ATTRIBUTES = Set.new(%i[
      id
      name
    ])

    def initialize(params)
      @params = params
    end

    def update_params
      {
        id: @params[:id],
        name: @params[:name]
      }
    end

    def valid?
      !@params[:name].blank? && !@params[:id].blank?
    end
  end
end
