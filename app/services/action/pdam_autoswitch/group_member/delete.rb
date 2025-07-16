module Action::PdamAutoswitch::GroupMember
  class Delete
    def initialize(params)
      @params = params
    end

    def run!
      member = PdamAutoswitchGroupMember.find_by_id(@params[:id])
      raise Exceptions::AutoswitchGroupMemberNotFound.new if member.nil? || member.deleted?

      ActiveRecord::Base.transaction do
        PdamAutoswitchGroupMemberSetting.where(autoswitch_group_member_id: member.id).delete_all
      end

      member.state = 'deleted'
      member.save!
    end
  end
end
