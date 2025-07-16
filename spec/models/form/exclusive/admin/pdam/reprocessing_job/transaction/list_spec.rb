# frozen_string_literal: true

require "rails_helper"

RSpec.describe Form::Exclusive::Admin::Pdam::ReprocessingJob::Transaction::List, type: :form do
  describe '.valid?' do
    subject { described_class.new(params).valid? }

    context 'when params is not valid' do
      context 'when job_id is not integer' do
        let(:params) do
          {
            job_id: 'a'
          }.with_indifferent_access
        end

        it { is_expected.to be_falsy }
      end

      context 'when job_id is blank' do
        let(:params) do
          {
            job_id: ''
          }
        end

        it { is_expected.to be_falsy }
      end
    end

    context 'when params is valid' do
      context 'when params is pure integer' do
        let(:params) do
          {
            job_id: 1
          }
        end

        it { is_expected.to be_truthy }
      end

      context 'when params is string but integer' do
        let(:params) do
          {
            job_id: '1'
          }
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.list_params' do
    let(:params) do
      {
        job_id: 1
      }
    end

    let(:expected_result) do
      {
        job_id: params[:job_id]
      }
    end

    subject { described_class.new(params).list_params }

    it { is_expected.to eq(expected_result) }
  end
end
