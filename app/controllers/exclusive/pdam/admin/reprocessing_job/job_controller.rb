# frozen_string_literal: truze

module Exclusive::Pdam::Admin::ReprocessingJob
  class JobController < ::PostpaidsController
    before_action :authorize!

    def index
      params[:offset] ||= DEFAULT_OFFSET
      params[:limit]  ||= DEFAULT_LIMIT

      form = Form::Exclusive::Admin::Pdam::ReprocessingJob::List.new(params)
      jobs, count = find_jobs(form.list_params)
      serialized_jobs = jobs.map { |job| serialize(job) }
      options = {
        http_status: HTTP_STATUS_OK,
        limit: form.list_params[:limit],
        offset: form.list_params[:offset],
        total: count
      }
      render_response_with_paginantion(serialized_jobs, HTTP_STATUS_OK, options)
    end

    private

    def authorize!
      token = get_token(request.env['HTTP_AUTHORIZATION'])
      decoded_token = JsonWebToken.decode(token)
      raise ::Exceptions::UnauthorizedUser.new unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
    end

    def find_jobs(params)
      jobs = ReprocessingJob.all
      filtered_jobs = jobs.limit(params[:limit]).offset(params[:offset]).order(id: :desc)
      [filtered_jobs, jobs.count]
    end

    def serialize(job)
      ::Serializer::Exclusive::Pdam::Admin::ReprocessingJob.new(job)
    end
  end
end
