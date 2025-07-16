# frozen_string_literal: true

module Action
  module PdamReprocessingTransaction
    class UnstuckTransaction
      attr_reader :transactions, :start_date, :end_date, :job, :user_id, :user_name

      include Postpaid::Constant

      def initialize(start_date, end_date, user_id, user_name)
        @start_date = start_date
        @end_date = end_date
        @user_id = user_id
        @user_name = user_name
      end

      def run!
        validate_datetime
        @start_date = start_date.in_time_zone('Jakarta').beginning_of_day
        @end_date = end_date.in_time_zone('Jakarta').end_of_day

        @transactions = get_processed_transaction_list
        raise Exceptions::ReprocessingJob::UnstuckTransactionNotFoundError if transactions.empty?

        @job = get_reprocessing_job
        if job.nil?
          @job = create_new_job
          map_transactions
        else
          raise Exceptions::ReprocessingJob::UnstuckJobIsProcessedError if job.processed?
        end

        errors = []
        reprocess(errors)

        job.state = 'succeeded'
        job.save!
        job
      end

      def validate_datetime
        parse_date

        @end_date = start_date if end_date.blank?
        day_difference = (end_date - start_date).to_i
        raise Exceptions::ReprocessingJob::InvalidDateError if day_difference < 0
        raise Exceptions::ReprocessingJob::MoreThanOneDayError if day_difference > 0

        today = Time.current.beginning_of_day
        raise Exceptions::ReprocessingJob::ExceedMaxDateError unless start_date < today
      end

      def parse_date
        @start_date = DateTime.parse(start_date)
        @end_date = DateTime.parse(end_date) unless end_date.blank?
      rescue
        raise Exceptions::ReprocessingJob::InvalidDateError
      end

      def get_processed_transaction_list
        ::PdamTransaction.where(created_at: start_date...end_date, state: :processed)
      end

      def get_reprocessing_job
        ::ReprocessingJob.find_by(stuck_transaction_date: start_date...end_date)
      end

      def create_new_job
        job = ReprocessingJob.new
        job.job_type = 'pdam'
        job.stuck_transaction_date = start_date
        job.state = 'processed'
        job.triggered_by_user_id = user_id
        job.triggered_by_user_name = user_name
        job.save!
        job
      end

      def map_transactions
        transactions.find_each do |transaction|
          map = ReprocessingTransactionMap.new
          map.job_id = job.id
          map.transaction_id = transaction.id
          map.save!
        end
      end

      def reprocess(errors)
        transactions.find_each do |transaction|
          payload = {
            remote_id: transaction.remote_transaction_id,
            product_type: transaction.product_type,
            options: {
              allow_processed: true
            }
          }
          topic_name = ::Subscribers::Topics::PARTNER_PROCESS
          GcpsPublisher.publish(topic_name, payload, track_id: payload[:remote_id]) if transaction.processed?
        rescue => e
          error_hash = {
            id: transaction.id,
            msg: e.message
          }
          errors << error_hash
        end
      end
    end
  end
end
