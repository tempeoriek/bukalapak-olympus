module Action::PdamAutoswitch::Group
  class Create
    def initialize(params)
      @params = params
    end

    def run!
      PdamAutoswitchGroup.where(name: @params[:name]).not_deleted.first.tap do | group |
        raise ::Exceptions::DuplicateAutoswitchGroup.new if group
      end

      PdamAutoswitchGroup.create(
      name: @params[:name],
      state: @params[:state]
      )
    end
  end
end
