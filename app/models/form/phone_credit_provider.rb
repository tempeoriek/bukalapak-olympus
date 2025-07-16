module Form
  class PhoneCreditProvider < Base
    def initialize(params)
      @params = params
    end

    def create_params
      @params
    end

    def update_params
      create_params
    end
  end
end