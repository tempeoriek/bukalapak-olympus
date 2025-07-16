module Serializer::Exclusive::Pdam::Admin
  class AutoswitchGroupMember
    def initialize(object)
      @object = object
    end

    def as_json(_options = {})
      {
        id: @object.id,
        operator: Serializer::Exclusive::PdamOperator.new(@object.operator),
        state: @object.state,
      }
    end
  end
end
