require "rails_helper"

RSpec.describe Exclusive::ElectricityPostpaidPartnerController, type: :controller do
  let(:partner_sepulsa) { create(:electricity_postpaid_partner, :sepulsa, :inactive) }
  let(:partner_bukopin) { create(:electricity_postpaid_partner, :bukopin, :active) }
  let(:partners) { [ partner_sepulsa, partner_bukopin ] }
  let(:expected_list_response) {
    JSON.parse([
      {
        id: partner_sepulsa.id,
        name: 'sepulsa',
        partner_admin_charge: 1000,
        bukalapak_admin_charge: 500,
        bukalapak_commission: 950,
        state: 'inactive',
        balance: [
          {
            amount: 10000000,
            threshold: 1000000,
            type: 'bukalapak'
          },
          {
            amount: 20000000,
            threshold: 2000000,
            type: 'mitra'
          },
          {
            amount: 30000000,
            threshold: 3000000,
            type: 'bukaconnect'
          }
        ],
        partner_type: 'normal'
      },
      {
        id: partner_bukopin.id,
        name: 'bukopin',
        partner_admin_charge: 2750,
        bukalapak_admin_charge: 0,
        bukalapak_commission: 0,
        state: 'active',
        balance: [],
        partner_type: 'normal'
      }
    ].to_json)
  }
  let(:header) {
    {
      "CONTENT_TYPE" => "application/json"
    }
  }

  let(:expected_update_response) {
    JSON.parse({
      id: partner_sepulsa.id,
      name: "sepulsa",
      partner_admin_charge: 1000,
      bukalapak_admin_charge: 500,
      bukalapak_commission: 950,
      state: 'active',
      balance: [
        {
          amount: 10000000,
          threshold: 1000000,
          type: "bukalapak"
        },
        {
          amount: 20000000,
          threshold: 2000000,
          type: "mitra"
        },
        {
          amount: 30000000,
          threshold: 3000000,
          type: "bukaconnect"
        }
      ],
      partner_type: 'normal'
    }.to_json)
  }

  let(:params_update) {
    JSON.parse({
      id: partner_sepulsa.id,
      state: 1
    }.to_json)
  }

  let(:params_update_with_balance) {
    JSON.parse({
      id: partner_sepulsa.id,
      state: 1,
      balance: [
        {
          amount: 10000000,
          threshold: 1000000,
          type: "bukalapak"
        },
        {
          amount: 20000000,
          threshold: 2000000,
          type: "mitra"
        },
        {
          amount: 30000000,
          threshold: 3000000,
          type: "bukaconnect"
        }
      ]
    }.to_json)
  }

  let(:params_update_with_inconsistency_balance) {
    JSON.parse({
      id: partner_sepulsa.id,
      state: 1,
      balance: [
        {
          amount: 10000000,
          threshold: 1000000,
          type: "hiyahiya"
        },
        {
          amount: 20000000,
          threshold: 2000000,
          type: "mitra"
        },
        {
          amount: 30000000,
          threshold: 3000000,
          type: "bukaconnect"
        }
      ]
    }.to_json)
  }

  let(:params_update_with_invalid_amount_balance) {
    JSON.parse({
      id: partner_sepulsa.id,
      state: 1,
      balance: [
        {
          amount: 0,
          threshold: 1000000,
          type: "bukalapak"
        },
        {
          amount: 20000000,
          threshold: 2000000,
          type: "mitra"
        },
        {
          amount: 30000000,
          threshold: 3000000,
          type: "bukaconnect"
        }
      ]
    }.to_json)
  }

  let(:params_update_with_invalid_threshold_balance) {
    JSON.parse({
      id: partner_sepulsa.id,
      state: 1,
      balance: [
        {
          amount: 10000,
          threshold: 1000000,
          type: "bukalapak"
        },
        {
          amount: 20000000,
          threshold: 2000000,
          type: "mitra"
        },
        {
          amount: 30000000,
          threshold: 0,
          type: "bukaconnect"
        }
      ]
    }.to_json)
  }

  before :all do
    described_class.skip_before_action :authorize!
  end

  describe 'GET #list' do
    before do
      allow(ElectricityPostpaidPartner).to receive(:all).and_return(partners)
      get :list
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(200)
      hash_body = JSON.parse(response.body)
      expect(hash_body['data']).to match(expected_list_response)
    end
  end

  describe 'patch #update' do
    before do
      request.headers.merge!(header)
      allow(::ElectricityPostpaidPartner).to receive(:find).and_return(partner_sepulsa)
    end

    it 'returns http success' do
      patch :update, params: params_update
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(200)
      hash_body = JSON.parse(response.body)
      expect(hash_body['data']).to match(expected_update_response)
    end

    context 'alert balances' do
      before do
        expected_update_response['balance'].each do |b|
          metric = {
            bukalapak: [Observer::Metric::TAGLIS_BALANCE, Observer::Metric::TAGLIS_THRESHOLD],
            mitra: [Observer::Metric::TAGLIS_BALANCE_MITRA, Observer::Metric::TAGLIS_THRESHOLD_MITRA],
            bukaconnect: [Observer::Metric::TAGLIS_BALANCE_BUKACONNECT, Observer::Metric::TAGLIS_THRESHOLD_BUKACONNECT]
          }[b['type'].to_sym]

          balance_metric_key = "#{metric[0]}_#{partner_sepulsa.name}".to_sym
          threshold_metric_key = "#{metric[1]}_#{partner_sepulsa.name}".to_sym
          expect(Observer).to receive(:gauge).with(balance_metric_key, b['amount'])
          expect(Observer).to receive(:gauge).with(threshold_metric_key, b['threshold'])
        end
      end

      it 'returns http success with balance in response' do
        patch :update, params: params_update_with_balance
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
        hash_body = JSON.parse(response.body)
        expect(hash_body['data']).to match(expected_update_response)
      end
    end

    it 'returns http error with inconsistency balance in response' do
      patch :update, params: params_update_with_inconsistency_balance
      expect(response).to have_http_status(422)
      expect(response.status).to eq(422)
      hash_body = JSON.parse(response.body)
      expect(hash_body['errors']).to match([
        {
          'code' => 18200,
          'message' => 'Tipe saldo tidak sesuai'
        }
      ])
    end

    it 'returns http error given balance amount is invalid' do
      patch :update, params: params_update_with_invalid_amount_balance
      expect(response).to have_http_status(422)
      expect(response.status).to eq(422)
      hash_body = JSON.parse(response.body)
      expect(hash_body['errors']).to match([
        {
          'code' => 181200,
          'message' => 'Invalid balance amount'
        }
      ])
    end

    it 'returns http error given balance threshold is invalid' do
      patch :update, params: params_update_with_invalid_threshold_balance
      expect(response).to have_http_status(422)
      expect(response.status).to eq(422)
      hash_body = JSON.parse(response.body)
      expect(hash_body['errors']).to match([
        {
          'code' => 181200,
          'message' => 'Invalid threshold amount'
        }
      ])
    end
  end

  describe 'get #get_balance' do
    let(:balance_bukalapak) { build(:keystore, key: BalanceTracker::ElectricityPostpaid::BUKALAPAK_BALANCE, value: 10000) }
    let(:threshold_bukalapak) { build(:keystore, key: BalanceTracker::ElectricityPostpaid::BUKALAPAK_THRESHOLD, value: 5000) }
    let(:balance_mitra) { build(:keystore, key: BalanceTracker::ElectricityPostpaid::MITRA_BALANCE, value: 10000) }
    let(:threshold_mitra) { build(:keystore, key: BalanceTracker::ElectricityPostpaid::MITRA_THRESHOLD, value: 5000) }

    let(:expected_response) do
      JSON.parse([
        {
          balance: 10000,
          threshold: 5000,
          type: 'bukalapak'
        },
        {
          balance: 10000,
          threshold: 5000,
          type: 'mitra'
        }
      ].to_json)
    end

    before do
      request.headers.merge!(header)
      expect(::Keystore).to receive(:find_by_key).with(BalanceTracker::ElectricityPostpaid::BUKALAPAK_BALANCE).and_return(balance_bukalapak)
      expect(::Keystore).to receive(:find_by_key).with(BalanceTracker::ElectricityPostpaid::MITRA_BALANCE).and_return(balance_mitra)
      expect(::Keystore).to receive(:find_by_key).with(BalanceTracker::ElectricityPostpaid::BUKALAPAK_THRESHOLD).and_return(threshold_bukalapak)
      expect(::Keystore).to receive(:find_by_key).with(BalanceTracker::ElectricityPostpaid::MITRA_THRESHOLD).and_return(threshold_mitra)

      get :get_balance
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(200)
      hash_body = JSON.parse(response.body)
      expect(hash_body['data']).to eq(expected_response)
    end
  end

  describe 'patch #modify_balance' do
    expectation = [
      {
        type: 'bukalapak',
        balance_key: BalanceTracker::ElectricityPostpaid::BUKALAPAK_BALANCE,
        threshold_key: BalanceTracker::ElectricityPostpaid::BUKALAPAK_THRESHOLD
      },
      {
        type: 'mitra',
        balance_key: BalanceTracker::ElectricityPostpaid::MITRA_BALANCE,
        threshold_key: BalanceTracker::ElectricityPostpaid::MITRA_THRESHOLD
      }
    ]

    expectation.each do |use_case|
      context "#{use_case[:type]} type" do
        let(:balance) { build(:keystore, key: use_case[:balance_key], value: 10000) }
        let(:threshold) { build(:keystore, key: use_case[:threshold_key], value: 5000) }
        let(:expected_response) do
          JSON.parse({
            balance: 10000,
            threshold: 5000,
            type: use_case[:type]
          }.to_json)
        end

        before do
          request.headers.merge!(header)
          expect(::Keystore).to receive(:set).with(use_case[:balance_key], 10000).and_return(balance)
          expect(::Keystore).to receive(:set).with(use_case[:threshold_key], 5000).and_return(threshold)

          patch :modify_balance, params: { balance: 10000, threshold: 5000, type: use_case[:type] }
        end

        it 'returns http success' do
          expect(response).to have_http_status(:success)
          expect(response.status).to eq(200)
          hash_body = JSON.parse(response.body)
          expect(hash_body['data']).to match(expected_response)
        end
      end
    end
  end
end
