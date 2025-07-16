module PdamAutoswitchHelper
  def select_active_operator_by_group_id(group_id)
    group = PdamAutoswitchGroup.find_by_id(group_id).tap do | group |
      raise ::Exceptions::AutoswitchGroupNotFound.new if group.nil? || group.deleted?
      raise ::Exceptions::AutoswitchGroupInactive.new if group.inactive?
    end

    PdamOperator.where(id: group.members.active.pluck(:operator_id)).active.first
  end
end
