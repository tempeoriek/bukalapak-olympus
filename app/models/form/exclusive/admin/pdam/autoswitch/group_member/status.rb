module Form::Exclusive::Admin::Pdam::Autoswitch::GroupMember
  class Status
    ATTRIBUTES = Set.new(%i[
      id
      group_id
      state
    ])

    def initialize(params)
      @params = params
    end

    def status_params
      {
        id: @params[:id],
        group_id: @params[:group_id],
        state: @params[:state]
      }
    end

    def valid?
      !@params[:state].blank? && !@params[:id].blank? && !@params[:group_id].blank?
    end
  end
end
