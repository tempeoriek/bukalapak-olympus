module Serializer::Exclusive::Pdam::Admin
  class AutoswitchGroupMemberSetting
    def initialize(object)
      @object = object
    end

    def as_json(_options = {})
      {
        id: @object.id,
        threshold_value: @object.threshold_value,
        threshold_min_trx: @object.threshold_min_trx,
        threshold_period_in_seconds: @object.threshold_period_in_seconds,
        threshold_type: @object.threshold_type,
        threshold_state: @object.threshold_state,
      }
    end
  end
end
