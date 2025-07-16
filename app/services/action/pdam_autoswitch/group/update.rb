module Action::PdamAutoswitch::Group
  class Update
    def initialize(params)
      @params = params
    end

    def run!
      group = PdamAutoswitchGroup.find_by_id(@params[:id]).tap do | group |
        raise ::Exceptions::AutoswitchGroupNotFound.new if group.nil? || group.deleted?
      end

      PdamAutoswitchGroup.where(name: @params[:name]).where.not(id: @params[:id]).not_deleted.first.tap do | group |
        raise ::Exceptions::DuplicateAutoswitchGroup.new if group
      end

      group.update(@params)
      group
    end
  end
end
