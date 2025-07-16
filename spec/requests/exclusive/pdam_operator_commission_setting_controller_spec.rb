require "rails_helper"

RSpec.describe Exclusive::PdamOperatorCommissionSettingController, type: :controller do
  before :all do
    described_class.skip_before_action :authorize!
  end
  let(:setting) { build_stubbed(:pdam_operator_commission_setting) }
  let(:request_body) do
    {
        operator_id: 1,
        value: 10000,
        state: 'active',
        min_transaction_value: 1,
        max_transaction_value: 100
    }
  end

  describe 'O2OVPE-1019: GET #show' do
    before do
      allow(PdamOperatorCommissionSetting).to receive(:find_by).and_return(setting)
      get :show, params: { operator_id: 1 }
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(200)
      hash_body = JSON.parse(response.body)
      expect(hash_body['data']['operator_id']).to match(setting.pdam_operator_id)
      expect(hash_body['data']['value']).to match(setting.value)
      expect(hash_body['data']['state']).to match(setting.state)
      expect(hash_body['data']['max_transaction_value']).to match(setting.max_transaction_value)
      expect(hash_body['data']['min_transaction_value']).to match(setting.min_transaction_value)
    end

    context 'when commission setting not found' do
      before do
        allow(PdamOperatorCommissionSetting).to receive(:find_by).and_return(nil)
        get :show, params: { operator_id: 1 }
      end

      it 'returns error' do
        expect(response).to have_http_status(404)
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'O2OVPE-1019: POST #create' do
    before do
        allow(Action::PdamOperatorCommissionSetting::Create).to receive_message_chain(:new, :run!).and_return(setting)
        post :create, params: request_body
    end

    it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(201)
        hash_body = JSON.parse(response.body)
        expect(hash_body['data']['operator_id']).to match(setting.pdam_operator_id)
        expect(hash_body['data']['value']).to match(setting.value)
        expect(hash_body['data']['state']).to match(setting.state)
        expect(hash_body['data']['max_transaction_value']).to match(setting.max_transaction_value)
        expect(hash_body['data']['min_transaction_value']).to match(setting.min_transaction_value)
    end

    context 'when param is missing fields' do
        before do
            post :create, params: { operator_id: 1, value: 1 }
        end

        it 'expects error' do
            expect(response).to have_http_status(422)
            expect(response.status).to eq(422)
        end
    end

    context 'when param is missing status' do
        before do
            post :create, params: { operator_id: 1, value: 0, min_transaction_value: 1, max_transaction_value: 100 }
        end

        it 'expects error' do
            expect(response).to have_http_status(422)
            expect(response.status).to eq(422)
        end
    end
  end

  describe 'O2OVPE-1019: PATCH #update' do
    before do
        allow(Action::PdamOperatorCommissionSetting::Update).to receive_message_chain(:new, :run!).and_return(setting)
        patch :update, params: request_body
    end

    it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(201)
        hash_body = JSON.parse(response.body)
        expect(hash_body['data']['operator_id']).to match(setting.pdam_operator_id)
        expect(hash_body['data']['value']).to match(setting.value)
        expect(hash_body['data']['state']).to match(setting.state)
        expect(hash_body['data']['max_transaction_value']).to match(setting.max_transaction_value)
        expect(hash_body['data']['min_transaction_value']).to match(setting.min_transaction_value)
    end

    context 'when param is missing fields' do
        before do
            post :create, params: { operator_id: 1, value: 1 }
        end

        it 'expects error' do
            expect(response).to have_http_status(422)
            expect(response.status).to eq(422)
        end
    end
  end

  describe 'O2OVPE-1019: not authorize' do
    before do
      described_class.before_action :authorize!
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false, role: 'user'} })
    end

    it 'should return http error (401)' do
      get :show, params: { operator_id: 1 }
      expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
      expect(response.status).to eq(401)
    end
  end
end
