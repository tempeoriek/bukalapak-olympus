require "rails_helper"

RSpec.describe Exclusive::GeneralCircuitBreakerController, type: :controller do
    let(:gmv) { 125_000 }
    let(:trx) { 101 }
    let(:now) { Time.find_zone('Asia/Jakarta').local(2023, 10, 13, 16, 59, 0) }
    let(:redis) { RedisOlympus }
    let(:expected_response) do
      {
        data: [
          {
            name: 'credit-card-bill',
            parameters: [
              {
                key: 'may_hourly_gmv',
                value: gmv,
                threshold: 689_743_155
              },
              {
                key: 'may_hourly_trx',
                value: trx,
                threshold: 5121
              }
            ],
            status: 'open'
          }
        ],
        meta: {
          http_status: 200
        }
      }.to_json
    end

  before :all do
    described_class.skip_before_action :authorize!
  end

  describe 'GET #list' do
    before do
      allow(Time).to receive(:now).and_return(now)
      allow(Config::GeneralCircuitBreaker).to receive(:config).and_return(credit_card_bill: GeneralCircuitBreaker::CreditCardBill::CONFIG)
      allow(redis).to receive(:get).with('credit-card-bill-hourly-trx:2023-10-13-16:00').and_return(trx)
      allow(redis).to receive(:get).with('credit-card-bill-hourly-gmv:2023-10-13-16:00').and_return(gmv)
      get :show
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(200)
      response_parsed = JSON.parse(response.body)
      expected_response_parsed = JSON.parse(expected_response)
      expect(response_parsed[:data]).to match(expected_response_parsed[:data])
    end
  end
end
