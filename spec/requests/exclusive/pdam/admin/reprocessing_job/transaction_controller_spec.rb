# frozen_string_literal: true

require "rails_helper"

RSpec.describe Exclusive::Pdam::Admin::ReprocessingJob::TransactionController, type: :controller do
  before do
    allow(JsonWebToken)
      .to receive(:decode)
      .and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
  end

  describe 'GET #index' do
    let(:params) do
      {
        job_id: 1
      }
    end

    subject { get :index, params: params }

    context 'when not authorized' do
      before do
        allow(JsonWebToken)
          .to receive(:decode)
          .and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'normal'} })
      end

      it 'returns unauthorized error' do
        subject
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
        expect(response.status).to eq(HTTP_STATUS_UNAUTHORIZED)
      end
    end

    context 'when params is valid' do
      let(:transaction_csv_data) { 'this is transaction csv string' }
      let(:transaction_mock) { double('transaction data') }
      let(:filename) { 'this is filename' }
      let(:csv_options) do
        {
          :type => 'text/csv; charset=utf-8; header=present',
          :disposition => "attachment; filename=#{filename}"
        }
      end

      before do
        expect(::Action::PdamReprocessingTransaction::GetTransaction)
          .to receive(:new)
          .with(params[:job_id])
          .and_return(transaction_mock)

        expect(transaction_mock)
          .to receive(:run!)
          .and_return([transaction_csv_data, filename])

        expect(@controller).to receive(:send_data).with(transaction_csv_data, csv_options) {
          @controller.render nothing: true # to prevent a 'missing template' error
        }
      end

      it 'will download csv data' do
        expect { subject }.not_to raise_error
        expect(response.status).to eq(HTTP_STATUS_OK)
      end
    end

    context 'when params is not integer' do
      let(:params) do
        {
          job_id: 'a'
        }.with_indifferent_access
      end

      it 'will returns http unprocessable entity error' do
        subject
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(181200)
        expect(response.status).to eq(HTTP_STATUS_UNPROCESSABLE_ENTITY)
      end
    end

    context 'when params is empty' do
      let(:params) do
        {
          job_id: ''
        }.with_indifferent_access
      end

      it 'will returns http unprocessable entity error' do
        subject
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(181200)
        expect(response.status).to eq(HTTP_STATUS_UNPROCESSABLE_ENTITY)
      end
    end
  end

  describe 'POST #reprocess' do
    let(:params) do
      {
        start_date: '2022-08-11',
        end_date: '2022-08-11'
      }
    end

    subject { post :reprocess, params: params }

    context 'when not authorized' do
      before do
        allow(JsonWebToken)
          .to receive(:decode)
          .and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'normal'} })
      end

      it 'returns unauthorized error' do
        subject
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
        expect(response.status).to eq(HTTP_STATUS_UNAUTHORIZED)
      end
    end

    context 'when invalid params' do
      context 'when start_date format is invalid' do
        let(:params) do
          {
            start_date: 'asdfasdf',
            end_date: '2022-08-11'
          }
        end

        it 'will returns http unprocessable entity error' do
          subject
          expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(181200)
          expect(response.status).to eq(HTTP_STATUS_UNPROCESSABLE_ENTITY)
        end
      end

      context 'when end_date format is invalid' do
        let(:params) do
          {
            start_date: '2022-08-11',
            end_date: 'asdfasdf'
          }
        end

        it 'will returns http unprocessable entity error' do
          subject
          expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(181200)
          expect(response.status).to eq(HTTP_STATUS_UNPROCESSABLE_ENTITY)
        end
      end

      context 'when start_date is empty' do
        let(:params) do
          {
            start_date: '',
            end_date: '2022-08-11'
          }
        end

        it 'will returns http unprocessable entity error' do
          subject
          expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(181200)
          expect(response.status).to eq(HTTP_STATUS_UNPROCESSABLE_ENTITY)
        end
      end
    end

    context 'when valid' do
      let(:expected_schema_response) { 'exclusive/pdam/admin/reprocessing_job/reprocessing_transaction' }
      let(:processed_job) { build_stubbed(:reprocessing_job, :processed) }
      let(:job_mock) { double('job_data') }

      context 'when given start_date and end_date' do
        before do
          expect(::Action::PdamReprocessingTransaction::UnstuckTransaction)
            .to receive(:new)
            .with(params[:start_date], params[:end_date], anything, anything)
            .and_return(job_mock)

          expect(job_mock)
            .to receive(:run!)
            .and_return(processed_job)
        end

        it 'will return job data with http status accepted' do
          expect { subject }.not_to raise_error
          expect(response.status).to eq(HTTP_STATUS_ACCEPTED)
          expect(response).to match_response_schema(expected_schema_response)
        end
      end

      context 'when given only start_date' do
        let(:params) do
          {
            start_date: '2022-08-11',
            end_date: ''
          }
        end

        before do
          expect(::Action::PdamReprocessingTransaction::UnstuckTransaction)
            .to receive(:new)
            .with(params[:start_date], params[:end_date], anything, anything)
            .and_return(job_mock)

          expect(job_mock)
            .to receive(:run!)
            .and_return(processed_job)
        end

        it 'will return job data with http status accepted' do
          expect { subject }.not_to raise_error
          expect(response.status).to eq(HTTP_STATUS_ACCEPTED)
          expect(response).to match_response_schema(expected_schema_response)
        end
      end
    end
  end
end
