# frozen_string_literal: true

module Exclusive::Pdam::Admin::ReprocessingJob
  class TransactionController < ::PostpaidsController
    before_action :authorize!

    def index
      form = ::Form::Exclusive::Admin::Pdam::ReprocessingJob::Transaction::List.new(params)
      raise ::Exceptions::InvalidParameterError unless form.valid?

      csv_data, filename = ::Action::PdamReprocessingTransaction::GetTransaction.new(form.list_params[:job_id]).run!

      send_data csv_data, :type => 'text/csv; charset=utf-8; header=present', :disposition => "attachment; filename=#{filename}"
    end

    def reprocess
      form = ::Form::Exclusive::Admin::Pdam::ReprocessingJob::Transaction::Create.new(params)
      raise ::Exceptions::InvalidParameterError unless form.valid?

      job = ::Action::PdamReprocessingTransaction::UnstuckTransaction.new(form.list_params[:start_date], form.list_params[:end_date], decoded_token[:resource_owner_id], decoded_token&.dig('resource_owner', 'username')).run!
      render_response(::Serializer::Exclusive::Pdam::Admin::ReprocessingJob.new(job), HTTP_STATUS_ACCEPTED)
    end

    private

    def authorize!
      token = get_token(request.env['HTTP_AUTHORIZATION'])
      decoded_token = JsonWebToken.decode(token)
      raise ::Exceptions::UnauthorizedUser.new unless exclusive_authorized_role?(decoded_token[:resource_owner][:role])
    end
  end
end
