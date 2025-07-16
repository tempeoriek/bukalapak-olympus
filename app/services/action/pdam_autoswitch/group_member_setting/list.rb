
module Action::PdamAutoswitch::GroupMemberSetting
  class List
    def initialize(params)
      @params = params
    end

    def run!
      PdamAutoswitchGroupMemberSetting.where(autoswitch_group_member_id: @params[:member_id])
    end
  end
end
