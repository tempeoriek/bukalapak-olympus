# frozen_string_literal: true

require "rails_helper"

RSpec.describe Form::Exclusive::Admin::Pdam::ReprocessingJob::Transaction::Create, type: :form do
  describe '.valid' do
    subject { described_class.new(params).valid? }

    context 'when params is not valid' do
      context 'when start_date format is invalid' do
        let(:params) do
          {
            start_date: 'asdfasdf',
            end_date: '2022-08-11'
          }
        end

        it { is_expected.to be_falsy }
      end

      context 'when end_date format is invalid' do
        let(:params) do
          {
            start_date: '2022-08-11',
            end_date: 'asdfasdf'
          }
        end

        it { is_expected.to be_falsy }
      end

      context 'when start_date is empty' do
        let(:params) do
          {
            start_date: '',
            end_date: '2022-08-11'
          }
        end

        it { is_expected.to be_falsy }
      end
    end

    context 'when params is valid' do
      context 'when given full params' do
        let(:params) do
          {
            start_date: '2022-08-11',
            end_date: '2022-08-11'
          }
        end

        it { is_expected.to be_truthy }
      end

      context 'when end_date is empty' do
        let(:params) do
          {
            start_date: '2022-08-11',
            end_date: ''
          }
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '.list_params' do
    let(:params) do
      {
        start_date: '2022-08-11',
        end_date: '2022-08-11'
      }
    end

    let(:expected_result) do
      {
        start_date: params[:start_date],
        end_date: params[:end_date]
      }
    end

    subject { described_class.new(params).list_params }

    it { is_expected.to eq(expected_result) }
  end
end
