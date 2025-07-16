module Form::Exclusive::Admin::Pdam::Autoswitch::GroupMember
  class Delete
    ATTRIBUTES = Set.new(%i[
      id
      group_id
    ])

    def initialize(params)
      @params = params
    end

    def delete_params
      {
        id: @params[:id],
        group_id: @params[:group_id],
      }
    end

    def valid?
      !@params[:id].blank? && !@params[:group_id].blank?
    end
  end
end
