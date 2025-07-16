# frozen_string_literal: true

require "rails_helper"

RSpec.describe Action::PdamReprocessingTransaction::GetTransaction, type: :model do
  let(:job_id) { 1 }
  let(:transaction_mock) { double('transaction_data') }
  let(:transaction_map_list) do
    [
      build_stubbed(:reprocessing_transaction_map),
      build_stubbed(:reprocessing_transaction_map),
      build_stubbed(:reprocessing_transaction_map)
    ]
  end

  let(:empty_transaction_map_list) { [] }
  let(:pdam_transaction) { build_stubbed(:pdam_transaction_with_bill) }
  let(:time_mock) { double('time_data') }
  let(:expected_time_format) { '04/08/2022 22:00' }
  let(:transaction_csv_string) { 'this is transaction csv string' }

  subject { described_class.new(job_id).run! }

  describe '.run!' do
    context 'when job is empty' do
      let(:empty_job) { }

      before do
        expect(::ReprocessingJob)
          .to receive(:find_by)
          .with(id: job_id)
          .and_return(empty_job)
      end

      it 'will raise JobNotFound error' do
        expect { subject }.to raise_error Exceptions::ReprocessingJob::JobNotFound
      end
    end

    context 'when job is nil' do
      let(:nil_job) { nil }

      before do
        expect(::ReprocessingJob)
          .to receive(:find_by)
          .with(id: job_id)
          .and_return(nil_job)
      end

      it 'will raise JobNotFound error' do
        expect { subject }.to raise_error Exceptions::ReprocessingJob::JobNotFound
      end
    end

    context 'when job status is processed' do
      let(:processed_job) { build_stubbed(:reprocessing_job, :processed) }

      before do
        expect(::ReprocessingJob)
          .to receive(:find_by)
          .with(id: job_id)
          .and_return(processed_job)

        expect(processed_job)
          .to receive(:processed?)
          .and_return(true)
      end

      it 'will raise job is processed error' do
        expect { subject }.to raise_error Exceptions::ReprocessingJob::JobIsProcessedError
      end
    end

    context 'when job status is succeeded' do
      let(:succeeded_job) { build_stubbed(:reprocessing_job, :succeeded) }

      before do
        expect(::ReprocessingJob)
          .to receive(:find_by)
          .with(id: job_id)
          .and_return(succeeded_job)

        expect(succeeded_job)
          .to receive(:processed?)
          .and_return(false)
      end

      context 'when total transaction is 0' do
        before do
          expect(::ReprocessingTransactionMap)
            .to receive(:includes)
            .with(:reprocessing_job, :pdam_transaction)
            .and_return(transaction_mock)

          expect(transaction_mock)
            .to receive(:where)
            .with(reprocessing_jobs: {
              id: job_id
            })
            .and_return(empty_transaction_map_list)
        end

        it 'will raise TransactionNotFound error' do
          expect { subject }.to raise_error Exceptions::ReprocessingJob::TransactionNotFound
        end
      end

      context 'when total transaction is more than 0' do
        before do
          expect(::ReprocessingTransactionMap)
            .to receive(:includes)
            .with(:reprocessing_job, :pdam_transaction)
            .and_return(transaction_mock)

          expect(transaction_mock)
            .to receive(:where)
            .with(reprocessing_jobs: {
              id: job_id
            })
            .and_return(transaction_map_list)

          transaction_map_list.map do |transaction|
            expect(transaction)
              .to receive(:reprocessing_job)
              .and_return(succeeded_job)
              .exactly(2).times

            expect(transaction)
              .to receive(:pdam_transaction)
              .and_return(pdam_transaction)
              .exactly(9).times

            expect(pdam_transaction.created_at)
              .to receive(:in_time_zone)
              .and_return(time_mock)

            expect(time_mock)
              .to receive(:strftime)
              .with("%d/%m/%Y %H:%M")
              .and_return(expected_time_format)

            expect(pdam_transaction.paid_at)
              .to receive(:in_time_zone)
              .and_return(time_mock)

            expect(time_mock)
              .to receive(:strftime)
              .with("%d/%m/%Y %H:%M")
              .and_return(expected_time_format)

          end.join("\n")
        end

        it 'will return transaction list on csv string format' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'when job status is failed' do
      let(:failed_job) { build_stubbed(:reprocessing_job, :failed) }

      before do
        expect(::ReprocessingJob)
          .to receive(:find_by)
          .with(id: job_id)
          .and_return(failed_job)

        expect(failed_job)
          .to receive(:processed?)
          .and_return(false)
      end

      context 'when total transaction is 0' do
        before do
          expect(::ReprocessingTransactionMap)
            .to receive(:includes)
            .with(:reprocessing_job, :pdam_transaction)
            .and_return(transaction_mock)

          expect(transaction_mock)
            .to receive(:where)
            .with(reprocessing_jobs: {
              id: job_id
            })
            .and_return(empty_transaction_map_list)
        end

        it 'will raise TransactionNotFound error' do
          expect { subject }.to raise_error Exceptions::ReprocessingJob::TransactionNotFound
        end
      end

      context 'when total transaction is more than 0' do
        before do
          expect(::ReprocessingTransactionMap)
            .to receive(:includes)
            .with(:reprocessing_job, :pdam_transaction)
            .and_return(transaction_mock)

          expect(transaction_mock)
            .to receive(:where)
            .with(reprocessing_jobs: {
              id: job_id
            })
            .and_return(transaction_map_list)

          transaction_map_list.map do |transaction|
            expect(transaction)
              .to receive(:reprocessing_job)
              .and_return(failed_job)
              .exactly(2).times

            expect(transaction)
              .to receive(:pdam_transaction)
              .and_return(pdam_transaction)
              .exactly(9).times

            expect(pdam_transaction.created_at)
              .to receive(:in_time_zone)
              .and_return(time_mock)

            expect(time_mock)
              .to receive(:strftime)
              .with("%d/%m/%Y %H:%M")
              .and_return(expected_time_format)

            expect(pdam_transaction.paid_at)
              .to receive(:in_time_zone)
              .and_return(time_mock)

            expect(time_mock)
              .to receive(:strftime)
              .with("%d/%m/%Y %H:%M")
              .and_return(expected_time_format)

          end.join("\n")
        end

        it 'will return transaction list on csv string format' do
          expect { subject }.not_to raise_error
        end
      end
    end
  end
end
