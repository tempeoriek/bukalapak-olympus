# frozen_string_literal: true

require 'csv'

module Action
  module PdamReprocessingTransaction
    class GetTransaction
      attr_reader :job_id

      include LoggerUtility

      def initialize(job_id)
        @job_id = job_id.to_i
      end

      def run!
        job = get_job
        raise Exceptions::ReprocessingJob::JobNotFound if job.nil?
        raise Exceptions::ReprocessingJob::JobIsProcessedError if job.processed?

        trxs = get_transaction_list
        raise Exceptions::ReprocessingJob::TransactionNotFound if trxs.size == 0

        csv_string = '';
        csv_string = trxs.map do |transaction|
          format_string(transaction)
        end.join("\n")

        csv_string.prepend(csv_header + "\n")

        today = Time.current.utc.in_time_zone('Jakarta')
        start_time = today.beginning_of_day
        filename = "BUKALAPAK#{start_time.strftime('%Y%m%d')}.csv"

        log_event("Reprocessed transaction for job id #{job_id} with #{trxs.size} transaction's count", %w[pdam reprocessing job service])

        [csv_string, filename]
      end

      def get_job
        ::ReprocessingJob.find_by(id: job_id)
      end

      def get_transaction_list
        ::ReprocessingTransactionMap.includes(:reprocessing_job, :pdam_transaction)
                                    .where(reprocessing_jobs: {
                                      id: job_id
                                    })
      end

      def format_string(transaction)
        row = [
          transaction.reprocessing_job.job_type,
          transaction.pdam_transaction.transaction_type,
          transaction.pdam_transaction.invoice_id,
          transaction.pdam_transaction.customer_number,
          transaction.pdam_transaction.id,
          transaction.pdam_transaction.remote_transaction_id,
          format_time(transaction.pdam_transaction.created_at),
          format_time(transaction.pdam_transaction.paid_at),
          transaction.pdam_transaction.state,
          transaction.pdam_transaction.amount,
          transaction.reprocessing_job.id,
        ]
        row.join(",")
      end

      def csv_header
        'product,buyer_type,invoice_id,customer_number,microservice_id,remote_id,created_at,paid_at,latest_state,amount,job_id'
      end

      def format_time(time)
        time.in_time_zone.strftime("%d/%m/%Y %H:%M")
      end
    end
  end
end
