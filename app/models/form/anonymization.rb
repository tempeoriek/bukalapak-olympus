module Form
  class Anonymization
    attr_accessor :user_id

    def initialize(params)
      @user_id = params[:user_id]
    end

    def valid?
      !@user_id.blank?
    end
  end
end