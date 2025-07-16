# frozen_string_literal: true

module Form::Exclusive::Admin::Pdam::ReprocessingJob::Transaction
  class List
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def list_params
      {
        job_id: params[:job_id]
      }
    end

    def valid?
      valid_integer? && !params[:job_id].blank?
    end

    def valid_integer?
      begin
        params[:job_id] = Integer(params[:job_id])
        true
      rescue
        false
      end
    end
  end
end
