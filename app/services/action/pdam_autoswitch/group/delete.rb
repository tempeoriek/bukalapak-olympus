module Action::PdamAutoswitch::Group
  class Delete
    def initialize(params)
      @params = params
    end

    def run!
      group = PdamAutoswitchGroup.find_by_id(@params[:id])
      raise Exceptions::AutoswitchGroupNotFound.new if group.nil?

      group.state = 'deleted'
      group.save!
    end
  end
end
