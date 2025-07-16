module Form::Exclusive::Admin::Pdam::Autoswitch::Group
  class List
    ATTRIBUTES = Set.new(%i[
        name
        offset
        limit
    ])

    DEFAULT_LIMIT = 10
    DEFAULT_OFFSET = 0

    def initialize(params)
      @params = params
    end

    def list_params
      {
        name: @params[:name],
        offset: @params[:offset] || DEFAULT_OFFSET,
        limit: @params[:limit] || DEFAULT_LIMIT
      }
    end

    def valid?
      if !@params[:name].nil?
        !/[[:alnum:]]/.match(@params[:name]).nil?
      else
        true
      end
    end
  end
end
