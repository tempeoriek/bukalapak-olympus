module Action::PdamAutoswitch::GroupMember
  class Create
    def initialize(params)
      @params = params
    end

    def run!
      group = PdamAutoswitchGroup.find_by_id(@params[:group_id]).tap do | group |
        raise ::Exceptions::AutoswitchGroupNotFound.new if group.nil? || group.deleted?
      end

      operator = PdamOperator.find_by_id(@params[:operator_id]).tap do | operator |
        raise ::Exceptions::InvalidPdamOperator.new if operator.nil?
      end

      member = PdamAutoswitchGroupMember.where(autoswitch_group_id: group.id, operator_id: operator.id).first

      return create_new_member(group, operator) if member.nil?
      return revive_member(member, @params.except(:operator_id, :group_id)) if member.deleted?
      raise ::Exceptions::DuplicateAutoswitchGroupMember.new if member.state != 'deleted'
    end

    private

    def create_new_member(group, operator)
      PdamAutoswitchGroupMember.create(
        autoswitch_group_id: group.id,
        operator_id: operator.id,
        state: @params[:state]
      )
    end

    def revive_member(member, params)
      member.update!(params)
      member
    end
  end
end
