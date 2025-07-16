require "rails_helper"

RSpec.describe Exclusive::Pdam::Admin::Autoswitch::GroupMemberSettingController, type: :controller do
  let(:header) {
    {
      "CONTENT_TYPE" => "application/json"
    }
  }

  let(:autoswitch_group_member_setting_structure) { 
    ["id", "threshold_value", "threshold_min_trx", "threshold_period_in_seconds", "threshold_type", "threshold_state"]
  }

  before :all do
    described_class.skip_before_action :authorize!
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
  end

  describe 'GET #index' do
    let(:autoswitch_group_member_settings) { [build_stubbed(:pdam_autoswitch_group_member_setting)] }

    context 'when given param' do
      before do
        allow_any_instance_of(Action::PdamAutoswitch::GroupMemberSetting::List).to receive(:run!).and_return autoswitch_group_member_settings
        get :index, params: { member_id: 1 }
      end

      it 'returns autoswitch group member settings & http success' do
        result = JSON.parse(response.body)
        expect(result['data'].length).to eq(1)
        expect(result['data'].first).to include(*autoswitch_group_member_setting_structure)

        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'POST #create' do
    let(:autoswitch_group_member_setting) { build_stubbed(:pdam_autoswitch_group_member_setting) }

    context 'given valid param' do
      let(:params) {
        {
          member_id: 1,
          threshold_value: 30,
          threshold_min_trx: 1,
          threshold_period_in_seconds: 15,
          threshold_type: 'processed_count',
          threshold_state: 'inactive'
        }
      }

      before do
        allow_any_instance_of(Action::PdamAutoswitch::GroupMemberSetting::Create).to receive(:run!).and_return autoswitch_group_member_setting
        
        post :create, params: params
      end

      it 'returns http success' do
        result = JSON.parse(response.body)
        expect(result['data']).to include(*autoswitch_group_member_setting_structure)

        expect(response).to have_http_status(:created)
        expect(response.status).to eq(201)
      end
    end

    context 'given invalid param' do
      before do
        post :create, params: { member_id: 1, threshold_value: 30 }
      end

      it 'returns http uproceessed entity' do
        expect(response.status).to eq(422)
      end
    end

    context 'given invalid param values' do
      let(:params_invalid_values) {
        {
          member_id: 1,
          threshold_value: -1,
          threshold_min_trx: -1,
          threshold_period_in_seconds: -15,
          threshold_type: 'processed',
          threshold_state: 'not_active'
        }
      }

      before do
        post :create, params: params_invalid_values
      end

      it 'returns http uproceessed entity' do
        expect(response.status).to eq(422)
      end
    end
  end

  describe 'PATCH #update' do
    let(:autoswitch_group_member_setting) { build_stubbed(:pdam_autoswitch_group_member_setting) }

    context 'given valid param' do
      let (:params) {
        {
          member_id: 1,
          id: autoswitch_group_member_setting.id,
          threshold_value: 30,
          threshold_min_trx: 1,
          threshold_period_in_seconds: 15,
          threshold_type: 'processed_count',
          threshold_state: 'inactive'
        }
      }

      context 'when autoswitch group member setting found' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::GroupMemberSetting::Update).to receive(:run!).and_return autoswitch_group_member_setting
          patch :update, params: params
        end

        it 'returns http success' do
          result = JSON.parse(response.body)
          expect(result['data']).to include(*autoswitch_group_member_setting_structure)

          expect(response).to have_http_status(:success)
          expect(response.status).to eq(200)
        end
      end

      context 'when autoswitch group member setting not found' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::GroupMemberSetting::Update).to receive(:run!).and_raise Exceptions::AutoswitchGroupMemberSettingNotFound
          patch :update, params: params
        end

        it 'returns http request not found' do
          expect(response.status).to eq(404)
          expect(JSON.parse(response.body)['errors'].first['message']).to eq 'Autoswitch Group Member Setting Not Found'
        end
      end
    end

    context 'given invalid param' do
      before do
        allow_any_instance_of(Action::PdamAutoswitch::GroupMemberSetting::Update).to receive(:run!).and_return nil

        patch :update, params: { member_id: 1, id: autoswitch_group_member_setting.id, threshold_value: 30 }
      end

      it 'returns http uproceessed entity' do
        expect(response.status).to eq(422)
      end
    end

    context 'given invalid param values' do
      let(:params_invalid_values) {
        {
          member_id: 1,
          id: autoswitch_group_member_setting.id,
          threshold_value: -1,
          threshold_min_trx: -1,
          threshold_period_in_seconds: -15,
          threshold_type: 'processed',
          threshold_state: 'not_active'
        }
      }

      before do
        post :update, params: params_invalid_values
      end

      it 'returns http uproceessed entity' do
        expect(response.status).to eq(422)
      end
    end
  end
end
