
module Action::PdamAutoswitch::Group
  class List
    def initialize(params)
      @params = params
    end

    def run!
      if @params[:name].present?
        # we are agreed to implement full table scan due to product needs
        # this query should not expossed to public due to performance concern
        # discussion can be found here https://bukalapak.slack.com/archives/GSFGAS0R4/p1630996695065400
        PdamAutoswitchGroup.where("name LIKE ?", "%#{@params[:name]}%").not_deleted.order(:name)
      else
        PdamAutoswitchGroup.not_deleted.order(:name)
      end
    end
  end
end
