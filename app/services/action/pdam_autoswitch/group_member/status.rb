module Action::PdamAutoswitch::GroupMember
  class Status
    def initialize(params)
      @params = params
    end

    def run!
      member = PdamAutoswitchGroupMember.find_by_id(@params[:id])
      raise Exceptions::AutoswitchGroupMemberNotFound.new if member.nil? || member.deleted?

      member.state = @params[:state]
      member.save!
      member
    end
  end
end
