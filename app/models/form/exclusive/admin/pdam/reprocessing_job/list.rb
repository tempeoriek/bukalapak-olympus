# frozen_string_literal: true

module Form::Exclusive::Admin::Pdam::ReprocessingJob
  class List
    attr_reader :params

    ATTRIBUTES = Set.new(%i[
        offset
        limit
    ])

    def initialize(params)
      @params = params
      valid?
    end

    def list_params
      {
        offset: params[:offset].to_i,
        limit: params[:limit].to_i
      }
    end

    def valid?
      validate_integer_params(params[:offset])
      validate_integer_params(params[:limit])
    end

    def validate_integer_params(param)
      raise ::Exceptions::InvalidParameterError unless param.to_s.match?('^[0-9]+$')
    end
  end
end
