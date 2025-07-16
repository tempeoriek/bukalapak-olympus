module Form
  class ElectricityPostpaidBalance < Base
    attr_accessor :balance, :threshold, :type

    MITRA_TYPE = 'mitra'.freeze

    def initialize(params)
      raise ::Exceptions::InvalidParameterError.new('Invalid balance amount') if params[:balance].to_i <= 0
      raise ::Exceptions::InvalidParameterError.new('Invalid threshold amount') if params[:threshold].to_i <= 0
      raise ::Exceptions::InvalidParameterError.new('Invalid type') if params[:type].nil? || %w[mitra bukalapak].exclude?(params[:type])

      @balance = params[:balance].to_i
      @threshold = params[:threshold].to_i
      @type = params[:type].to_s.downcase
    end

    def mitra?
      @type == MITRA_TYPE
    end
  end
end
