module Form::Exclusive::Admin::Pdam::Autoswitch::Group
  class Delete
    ATTRIBUTES = Set.new(%i[
      id
    ])

    def initialize(params)
      @params = params
    end

    def delete_params
      {
        id: @params[:id],
      }
    end

    def valid?
      !@params[:id].blank?
    end
  end
end
