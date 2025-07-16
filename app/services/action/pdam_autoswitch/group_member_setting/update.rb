module Action::PdamAutoswitch::GroupMemberSetting
  class Update
    def initialize(params)
      @params = params
    end

    def run!
      setting = PdamAutoswitchGroupMemberSetting.find_by_id(@params[:id])
      raise Exceptions::AutoswitchGroupMemberSettingNotFound.new if setting.nil?

      setting.threshold_value = @params[:threshold_value]
      setting.threshold_min_trx = @params[:threshold_min_trx]
      setting.threshold_period_in_seconds = @params[:threshold_period_in_seconds]
      setting.threshold_type = @params[:threshold_type]
      setting.threshold_state = @params[:threshold_state]
      setting.save!
      setting
    end
  end
end
