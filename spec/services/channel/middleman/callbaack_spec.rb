require 'rails_helper'
require 'json'

RSpec.describe Channel::Middleman::Callback, type: :model do
  let(:transaction) { build_stubbed(:postpaid_transaction_with_bill) }

  subject { described_class.new(transaction) }

  describe 'run!' do
    context 'when get success response' do
      let(:success_response) {
        {"message"=>"Collecting agent transaction status has been updated", "meta"=>{"http_status"=>200}}
      }

      let(:expected_tags) {
        {
          action: 'callback',
          partner: 'middleman',
          product: 'electricity_postpaid',
          status:  :success,
          response_code: 200
        }
      }

      before do
        allow(Channel::Connection::Http).to receive(:post).and_return(success_response.to_json)
      end

      it 'log and publish success metric' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::PARTNER, kind_of(Numeric), expected_tags)
        expect{subject.run!}.not_to raise_error
      end
    end

    context 'when get non success response' do
      let(:expected_tags) {
        {
          action: 'callback',
          partner: 'middleman',
          product: 'electricity_postpaid',
          status:  :error,
          response_code: 500
        }
      }

      before do
        stub_request(:post, Channel::Middleman::Callback::URL).
            to_return(:status => 500, :body => "Internal Server Error 500", :headers => {})
      end

      it 'log and publish failed metric' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::PARTNER, kind_of(Numeric), expected_tags)
        expect{subject.run!}.not_to raise_error
      end
    end

    context 'when credit card bill' do
      let(:transaction) { build_stubbed(:cc_transaction) }
      let(:success_response) {
        {"message"=>"Collecting agent transaction status has been updated", "meta"=>{"http_status"=>200}}
      }

      let(:expected_tags) {
        {
          action: 'callback',
          partner: 'middleman',
          product: 'credit-card-bill',
          status:  :success,
          response_code: 200
        }
      }

      before do
        allow(Channel::Connection::Http).to receive(:post).and_return(success_response.to_json)
      end

      it 'log and publish success metric' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)
        expect(Observer).to receive(:histogram).with(Observer::Metric::PARTNER, kind_of(Numeric), expected_tags)
        expect(transaction).to receive(:middleman_response_code)
        expect(transaction).to receive(:middleman_failed_reason)
        expect{subject.run!}.not_to raise_error
      end
    end
  end
end
