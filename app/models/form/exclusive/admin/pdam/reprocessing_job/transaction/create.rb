# frozen_string_literal: true

module Form::Exclusive::Admin::Pdam::ReprocessingJob::Transaction
  class Create
    attr_reader :params

    ATTRIBUTES = Set.new(%i[
      start_date
      end_date
    ])

    def initialize(params)
      @params = params
      valid?
    end

    def list_params
      {
        start_date: params[:start_date],
        end_date: params[:end_date]
      }
    end

    def valid?
      params[:start_date].present? && valid_datetime_format?
    end

    def valid_datetime_format?
      DateTime.parse(params[:start_date])
      DateTime.parse(params[:end_date]) unless params[:end_date].blank?
      true
    rescue
      false
    end
  end
end
