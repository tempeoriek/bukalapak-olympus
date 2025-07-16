# frozen_string_literal: true

require "rails_helper"

RSpec.describe Exclusive::Pdam::Admin::ReprocessingJob::JobController, type: :controller do
  let(:reprocessing_job_structure) do
    %w[id state stuck_transaction_date triggered_by_user_id triggered_by_user_name created_at updated_at]
  end
  let(:reprocessing_jobs) { build_list(:reprocessing_job, 2) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow(JsonWebToken)
      .to receive(:decode)
      .and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'admin'} })
  end

  describe 'GET #index' do
    subject { get :index, params: params }

    let(:reprocessing_job_relation) do
      relation = ReprocessingJob::all
      record = double("ReprocessingJob")
      relation
    end

    context 'when not authorized' do
      let(:params) { nil }
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

    context 'when given no param' do
      let(:params) { nil }

      before do
        expect_any_instance_of(reprocessing_job_relation.class).to receive_message_chain(:limit, :offset, :order).and_return(reprocessing_jobs)
      end

      it 'returns reprocessing jobs & http success' do
        subject
        result = JSON.parse(response.body)
        expect(result['data'].length).to eq(2)
        expect(result['data'].first).to include(*reprocessing_job_structure)
        expect(result['meta']).to include("limit", "offset", "total")

        expect(response).to have_http_status(:success)
        expect(response.status).to eq(HTTP_STATUS_OK)
      end
    end

    context 'given invalid limit param' do
      let(:params) { {limit: '-'} }

      it 'returns http unprocessable entity' do
        subject
        expect(response.status).to eq(HTTP_STATUS_UNPROCESSABLE_ENTITY)
      end
    end

    context 'given invalid offset param' do
      let(:params) { {offset: '-'} }

      it 'returns http unprocessable entity' do
        subject
        expect(response.status).to eq(HTTP_STATUS_UNPROCESSABLE_ENTITY)
      end
    end

    context 'given valid limit and offset param' do
      let(:params) { { limit: 20, offset: 10 } }

      before do
        expect_any_instance_of(reprocessing_job_relation.class).to receive_message_chain(:limit, :offset, :order).and_return(reprocessing_jobs)
      end

      it 'returns reprocessing jobs & http success' do
        subject
        result = JSON.parse(response.body)
        expect(result['data'].length).to eq(2)
        expect(result['data'].first).to include(*reprocessing_job_structure)
        expect(result['meta']).to include("limit", "offset", "total")

        expect(response).to have_http_status(:success)
        expect(response.status).to eq(HTTP_STATUS_OK)
      end
    end
  end
end
