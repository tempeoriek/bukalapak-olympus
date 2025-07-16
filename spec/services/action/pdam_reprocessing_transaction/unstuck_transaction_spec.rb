# frozen_string_literal: true

require "rails_helper"

RSpec.describe Action::PdamReprocessingTransaction::UnstuckTransaction, type: :model do
  describe '.run!' do
    let(:user_id) { 1 }
    let(:user_name) { 'Ritxman' }
    subject { described_class.new(start_date, end_date, user_id, user_name).run! }

    context 'when date params is not valid' do
      context 'when given invalid start_date' do
        let(:start_date) { 'asdfasdf' }
        let(:end_date) { '' }

        it 'will raise InvalidDateError' do
          expect { subject }.to raise_error(Exceptions::ReprocessingJob::InvalidDateError)
        end
      end

      context 'when given invalid end_date' do
        let(:start_date) { '2022-08-10' }
        let(:end_date) { 'asdfasdf' }

        it 'will raise InvalidDateError' do
          expect { subject }.to raise_error(Exceptions::ReprocessingJob::InvalidDateError)
        end
      end

      context 'when end_date is less than start_date' do
        let(:start_date) { Time.now.strftime("%d/%m/%Y") }
        let(:end_date) { 2.days.ago.strftime("%d/%m/%Y") }

        it 'will raise InvalidDateError' do
          expect { subject }.to raise_error(Exceptions::ReprocessingJob::InvalidDateError)
        end
      end

      context 'when start_date and end_date range is more than 1 day' do
        let(:start_date) { Time.now.strftime("%d/%m/%Y") }
        let(:end_date) { 2.days.from_now.strftime("%d/%m/%Y") }

        it 'will raise MoreThanOneDayError' do
          expect { subject }.to raise_error(Exceptions::ReprocessingJob::MoreThanOneDayError)
        end
      end

      context 'when start_date is today' do
        let(:start_date) { Time.now.in_time_zone('Asia/Jakarta').strftime("%d/%m/%Y") }
        let(:end_date) { Time.now.in_time_zone('Asia/Jakarta').strftime("%d/%m/%Y") }

        it 'will raise MoreThanOneDayError' do
          expect { subject }.to raise_error(Exceptions::ReprocessingJob::ExceedMaxDateError)
        end
      end

      context 'when start_date is more than today' do
        let(:start_date) { 1.days.from_now.strftime("%d/%m/%Y") }
        let(:end_date) { 1.days.from_now.strftime("%d/%m/%Y") }

        it 'will raise MoreThanOneDayError' do
          expect { subject }.to raise_error(Exceptions::ReprocessingJob::ExceedMaxDateError)
        end
      end
    end

    context 'when date params is valid' do
      let(:start_date) { 1.days.ago.strftime("%d/%m/%Y") }
      let(:end_date) { 1.days.ago.strftime("%d/%m/%Y") }
      let(:expected_start_date_format) { 1.days.ago.in_time_zone('Jakarta').beginning_of_day }
      let(:expected_end_date_format) { 1.days.ago.in_time_zone('Jakarta').end_of_day}
      let(:empty_transaction) { [] }
      let(:pdam_transaction) { build_stubbed(:pdam_transaction_with_bill, :processed) }
      let(:transaction_mock) { double('transaction_data') }
      let(:no_job) { nil }
      let(:processed_job) { build_stubbed(:reprocessing_job, :processed) }
      let(:succeeded_job) { build_stubbed(:reprocessing_job, :succeeded) }
      let(:failed_job) { build_stubbed(:reprocessing_job, :failed) }
      let(:topic_name) { ::Subscribers::Topics::PARTNER_PROCESS }
      let(:reprocessing_transaction_map) { build_stubbed(:reprocessing_transaction_map) }

      context 'when processed transaction list is empty' do
        before do
          expect(::PdamTransaction)
            .to receive(:where)
            .with(created_at: expected_start_date_format...expected_end_date_format, state: :processed)
            .and_return(empty_transaction)
        end

        it 'will raise UnstuckTransactionNotFoundError' do
          expect { subject }.to raise_error(Exceptions::ReprocessingJob::UnstuckTransactionNotFoundError)
        end
      end

      context 'when job is existed' do
        context 'when job is in processed state' do
          before do
            expect(::PdamTransaction)
              .to receive(:where)
              .with(created_at: expected_start_date_format...expected_end_date_format, state: :processed)
              .and_return(transaction_mock)

            expect(transaction_mock)
              .to receive(:empty?)
              .and_return(false)

            expect(::ReprocessingJob)
              .to receive(:find_by)
              .with(stuck_transaction_date: expected_start_date_format...expected_end_date_format)
              .and_return(processed_job)
          end

          it 'will raise UnstuckJobIsProcessedError' do
            expect { subject }.to raise_error(Exceptions::ReprocessingJob::UnstuckJobIsProcessedError)
          end
        end

        context 'when job is in succeeded state' do
          context 'when no error while reprocessing transaction' do
            context 'when there is any processed transaction' do
              before do
                expect(::PdamTransaction)
                  .to receive(:where)
                  .with(created_at: expected_start_date_format...expected_end_date_format, state: :processed)
                  .and_return(transaction_mock)

                expect(transaction_mock)
                  .to receive(:empty?)
                  .and_return(false)

                expect(::ReprocessingJob)
                  .to receive(:find_by)
                  .with(stuck_transaction_date: expected_start_date_format...expected_end_date_format)
                  .and_return(succeeded_job)

                expect(transaction_mock)
                  .to receive(:find_each)
                  .and_yield(pdam_transaction)

                expect(GcpsPublisher)
                  .to receive(:publish)
                  .with(topic_name, anything, anything)
                  .exactly(1).times

                expect(succeeded_job)
                  .to receive(:save!)
                  .and_return(true)
              end

              it 'will reprocessing only processed transaction without creating new job' do
                expect { subject }.not_to raise_error
              end
            end
          end

          context 'when there is error' do
            before do
              expect(::PdamTransaction)
                .to receive(:where)
                .with(created_at: expected_start_date_format...expected_end_date_format, state: :processed)
                .and_return(transaction_mock)

              expect(transaction_mock)
                .to receive(:empty?)
                .and_return(false)

              expect(::ReprocessingJob)
                .to receive(:find_by)
                .with(stuck_transaction_date: expected_start_date_format...expected_end_date_format)
                .and_return(succeeded_job)

              expect(transaction_mock)
                .to receive(:find_each)
                .and_yield(pdam_transaction)

              expect(GcpsPublisher)
                .to receive(:publish)
                .with(topic_name, anything, anything)
                .and_raise(StandardError)

              expect(succeeded_job)
                .to receive(:save!)
                .and_return(true)
            end

            it 'will not raise error' do
              expect { subject }.not_to raise_error
            end
          end
        end

        context 'when job is in failed state' do
          context 'when there is no error while reprocessing transaction' do
            context 'when there is any processed transaction' do
              before do
                expect(::PdamTransaction)
                  .to receive(:where)
                  .with(created_at: expected_start_date_format...expected_end_date_format, state: :processed)
                  .and_return(transaction_mock)

                expect(transaction_mock)
                  .to receive(:empty?)
                  .and_return(false)

                expect(::ReprocessingJob)
                  .to receive(:find_by)
                  .with(stuck_transaction_date: expected_start_date_format...expected_end_date_format)
                  .and_return(failed_job)

                expect(transaction_mock)
                  .to receive(:find_each)
                  .and_yield(pdam_transaction)

                expect(GcpsPublisher)
                  .to receive(:publish)
                  .with(topic_name, anything, anything)
                  .exactly(1).times

                expect(failed_job)
                  .to receive(:save!)
                  .and_return(true)
              end

              it 'will reprocessing only processed transaction without creating new job' do
                expect { subject }.not_to raise_error
              end
            end
          end

          context 'when there is error while reprocessing transaction' do
            before do
              expect(::PdamTransaction)
                .to receive(:where)
                .with(created_at: expected_start_date_format...expected_end_date_format, state: :processed)
                .and_return(transaction_mock)

              expect(transaction_mock)
                .to receive(:empty?)
                .and_return(false)

              expect(::ReprocessingJob)
                .to receive(:find_by)
                .with(stuck_transaction_date: expected_start_date_format...expected_end_date_format)
                .and_return(failed_job)

              expect(transaction_mock)
                .to receive(:find_each)
                .and_yield(pdam_transaction)

              expect(GcpsPublisher)
                .to receive(:publish)
                .with(topic_name, anything, anything)
                .and_raise(StandardError)

              expect(failed_job)
                .to receive(:save!)
                .and_return(true)
            end

            it 'will not raise error' do
              expect { subject }.not_to raise_error
            end
          end
        end
      end

      context 'when there is no job' do
        before do
          expect(::PdamTransaction)
            .to receive(:where)
            .with(created_at: expected_start_date_format...expected_end_date_format, state: :processed)
            .and_return(transaction_mock)

          expect(transaction_mock)
            .to receive(:empty?)
            .and_return(false)

          expect(::ReprocessingJob)
            .to receive(:find_by)
            .with(stuck_transaction_date: expected_start_date_format...expected_end_date_format)
            .and_return(no_job)

          expect(transaction_mock)
            .to receive(:find_each)
            .and_yield(pdam_transaction)
            .exactly(2).times

          expect(ReprocessingJob)
            .to receive(:new)
            .and_return(processed_job)

          expect(processed_job)
            .to receive(:save!)
            .and_return(true)

          expect(ReprocessingTransactionMap)
            .to receive(:new)
            .and_return(reprocessing_transaction_map)

          expect(reprocessing_transaction_map)
            .to receive(:save!)
            .and_return(true)
        end

        context 'when there is no error while reprocessing transaction' do
          before do
            expect(GcpsPublisher)
              .to receive(:publish)
              .with(topic_name, anything, anything)

            expect(processed_job)
              .to receive(:save!)
              .and_return(true)
          end

          it 'will not raise error' do
            expect { subject }.not_to raise_error
          end
        end

        context 'when there is error while reprocessing transaction' do
          before do
            expect(GcpsPublisher)
              .to receive(:publish)
              .with(topic_name, anything, anything)
              .and_raise(StandardError)

            expect(processed_job)
              .to receive(:save!)
              .and_return(true)
          end

          it 'will not raise error' do
            expect { subject }.not_to raise_error
          end
        end
      end
    end
  end
end
