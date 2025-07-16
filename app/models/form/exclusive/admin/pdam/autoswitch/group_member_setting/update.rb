module Form::Exclusive::Admin::Pdam::Autoswitch::GroupMemberSetting
  class Update
    ATTRIBUTES = Set.new(%i[
        id
        threshold_value
        threshold_min_trx
        threshold_period_in_seconds
        threshold_type
        threshold_state
    ])

    def initialize(params)
      @params = params
    end

    def update_params
      {
        id: @params[:id],
        threshold_value: @params[:threshold_value],
        threshold_min_trx: @params[:threshold_min_trx],
        threshold_period_in_seconds: @params[:threshold_period_in_seconds],
        threshold_type: @params[:threshold_type],
        threshold_state: @params[:threshold_state]
      }
    end

    def valid?
      is_value_valid = !@params[:threshold_value].blank? && @params[:threshold_value].to_i >= 0
      is_min_trx_valid = !@params[:threshold_min_trx].blank? && @params[:threshold_min_trx].to_i >= 0
      is_period_valid = !@params[:threshold_period_in_seconds].blank? && @params[:threshold_period_in_seconds].to_i >= 0
      is_type_valid = !@params[:threshold_type].blank? &&
        PdamAutoswitchGroupMemberSetting.is_type_valid(@params[:threshold_type])
      is_state_valid = !@params[:threshold_state].blank? &&
        PdamAutoswitchGroupMemberSetting.is_state_valid(@params[:threshold_state])

      !@params[:id].blank? &&
      is_value_valid &&
      is_min_trx_valid &&
      is_period_valid &&
      is_type_valid &&
      is_state_valid
    end
  end
end
