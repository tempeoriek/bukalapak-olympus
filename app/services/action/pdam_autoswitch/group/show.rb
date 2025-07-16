module Action::PdamAutoswitch::Group
  class Show
    def initialize(params)
      @params = params
    end

    def run!
      PdamAutoswitchGroup.find_by_id(@params[:id]).tap do | group |
         raise ::Exceptions::AutoswitchGroupNotFound.new if group.nil? || group.deleted?
      end
    end
  end
end
