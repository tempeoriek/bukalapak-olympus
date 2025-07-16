require "rails_helper"

RSpec.describe Exclusive::Pdam::Admin::Autoswitch::GroupMemberController, type: :controller do
  let(:autoswitch_group_member_id) { 1 }

  let(:header) {
    {
      "CONTENT_TYPE" => "application/json"
    }
  }

  let(:autoswitch_group_member_structure) { ["id", "operator", "state"] }

  before :all do
    described_class.skip_before_action :authorize!
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
  end

  describe 'POST #create' do
    let(:autoswitch_group_member) { build_stubbed(:pdam_autoswitch_group_member) }

    context 'given valid param' do
      before do
        allow_any_instance_of(Action::PdamAutoswitch::GroupMember::Create).to receive(:run!).and_return autoswitch_group_member

        post :create, params: { group_id: 1, operator_id: 1, state: 'active' }
      end

      it 'returns http success' do
        result = JSON.parse(response.body)
        expect(result['data']).to include(*autoswitch_group_member_structure)

        expect(response).to have_http_status(:created)
        expect(response.status).to eq(201)
      end
    end

    context 'given invalid param' do
      before do
        post :create, params: { group_id: 1, state: 'active' }
      end

      it 'returns http uproceessed entity' do
        expect(response.status).to eq(422)
      end
    end
  end

  describe 'DELETE #delete' do
    let(:autoswitch_group_member) { build_stubbed(:pdam_autoswitch_group_member) }

    context 'given valid param' do
      context 'when autoswitch group found' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::GroupMember::Delete).to receive(:run!).and_return true
          delete :delete, params: { id: autoswitch_group_member.id, group_id: 1}
        end

        it 'returns http success' do
          expect(response).to have_http_status(:success)
          expect(response.status).to eq(200)
        end
      end

      context 'when autoswitch group not found' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::GroupMember::Delete).to receive(:run!).and_raise Exceptions::AutoswitchGroupMemberNotFound
          delete :delete, params: { id: autoswitch_group_member.id, group_id: 1 }
        end

        it 'returns http request not found' do
          expect(response.status).to eq(404)
          expect(JSON.parse(response.body)['errors'].first['message']).to eq 'Autoswitch Group Member Not Found'
        end
      end
    end
  end

  describe 'PATCH #status' do
    let(:autoswitch_group_member) { build_stubbed(:pdam_autoswitch_group_member) }

    context 'given valid param' do
      context 'when autoswitch group found' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::GroupMember::Status).to receive(:run!).and_return autoswitch_group_member
          patch :status, params: { id: autoswitch_group_member.id, state: 'active', group_id: 1}
        end

        it 'returns http success' do
          result = JSON.parse(response.body)
          expect(result['data']).to include(*autoswitch_group_member_structure)

          expect(response).to have_http_status(:success)
          expect(response.status).to eq(200)
        end
      end

      context 'when autoswitch group not found' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::GroupMember::Status).to receive(:run!).and_raise Exceptions::AutoswitchGroupMemberNotFound
          patch :status, params: { id: autoswitch_group_member.id, state: 'active',  group_id: 1}
        end

        it 'returns http request not found' do
          expect(response.status).to eq(404)
          expect(JSON.parse(response.body)['errors'].first['message']).to eq 'Autoswitch Group Member Not Found'
        end
      end
    end

    context 'given invalid param' do
      before do
        allow_any_instance_of(Action::PdamAutoswitch::GroupMember::Status).to receive(:run!).and_return nil

        patch :status, params: { id: autoswitch_group_member.id, group_id: 1 }
      end

      it 'returns http uproceessed entity' do
        expect(response.status).to eq(422)
      end
    end
  end
end
