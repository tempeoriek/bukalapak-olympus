module Action::PdamAutoswitch::GroupMemberSetting
  class Create
    def initialize(params)
      @params = params
    end

    def run!
      member = PdamAutoswitchGroupMember.find_by_id(@params[:member_id]).tap do | member |
        raise ::Exceptions::AutoswitchGroupMemberNotFound.new if member.nil? || member.deleted?
      end

      return PdamAutoswitchGroupMemberSetting.create(
        autoswitch_group_member_id: member.id,
        threshold_value: @params[:threshold_value],
        threshold_min_trx: @params[:threshold_min_trx],
        threshold_period_in_seconds: @params[:threshold_period_in_seconds],
        threshold_type: @params[:threshold_type],
        threshold_state: @params[:threshold_state],
      )
    end
  end
end
