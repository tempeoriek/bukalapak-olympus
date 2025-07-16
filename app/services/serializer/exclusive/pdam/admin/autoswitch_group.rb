module Serializer::Exclusive::Pdam::Admin
  class AutoswitchGroup
    def initialize(object)
      @object = object
    end

    def as_json(_options = {})
      {
        id: @object.id,
        name: @object.name,
        members: @object.members.not_deleted.map { |member| Serializer::Exclusive::Pdam::Admin::AutoswitchGroupMember.new(member) },
        state: @object.state,
      }
    end
  end
end
