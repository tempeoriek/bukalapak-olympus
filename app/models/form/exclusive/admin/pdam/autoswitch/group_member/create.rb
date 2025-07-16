module Form::Exclusive::Admin::Pdam::Autoswitch::GroupMember
  class Create
    ATTRIBUTES = Set.new(%i[
        group_id
        operator_id
        state
    ])

    def initialize(params)
      @params = params
    end

    def create_params
      {
        group_id: @params[:group_id],
        operator_id: @params[:operator_id],
        state: @params[:state]
      }
    end

    def valid?
      !@params[:group_id].blank? && !@params[:state].blank? && !@params[:operator_id].blank?
    end
  end
end
