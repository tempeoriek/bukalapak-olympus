module Action::PdamAutoswitch::Group
  class Status
    def initialize(params)
      @params = params
    end

    def run!
      group = PdamAutoswitchGroup.find_by_id(@params[:id]).tap do | group |
        raise ::Exceptions::AutoswitchGroupNotFound.new if group.nil? || group.deleted?
      end

      group.state = @params[:state]
      group.save!

      if @params[:state].in?(['inactive', 'deleted'])
        PdamAutoswitchGroupMember.where(autoswitch_group_id: group.id).update_all(state: @params[:state])
      end

      group
    end
  end
end
