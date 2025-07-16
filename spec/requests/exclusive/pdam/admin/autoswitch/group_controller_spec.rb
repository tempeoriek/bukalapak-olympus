require "rails_helper"

RSpec.describe Exclusive::Pdam::Admin::Autoswitch::GroupController, type: :controller do
  let(:autoswitch_group_id) { 1 }

  let(:header) {
    {
      "CONTENT_TYPE" => "application/json"
    }
  }

  let(:autoswitch_group_structure) { ["id", "name", "members", "state"] }

  before :all do
    described_class.skip_before_action :authorize!
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
  end


  describe 'GET #index' do
    let(:autoswitch_group_relation) {
      relation = PdamAutoswitchGroup::where(id: 1)
      record = double("PdamAutoswitchGroup")
      relation.stub(:[]).and_return([record])
      relation

    }
    let(:autoswitch_groups) { [build_stubbed(:pdam_autoswitch_group, :with_members)] }

    context 'when given no param' do
      before do
        allow_any_instance_of(Action::PdamAutoswitch::Group::List).to receive(:run!).and_return autoswitch_group_relation
        allow_any_instance_of(autoswitch_group_relation.class).to receive_message_chain(:limit, :offset).and_return(autoswitch_groups)
        get :index
      end

      it 'returns autoswitch groups & http success' do
        result = JSON.parse(response.body)
        expect(result['data'].length).to eq(1)
        expect(result['data'].first).to include(*autoswitch_group_structure)
        expect(result['meta']).to include("limit", "offset", "total")

        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end

    context 'given invalid name param' do
      before do
        get :index, params: { name: '-' }
      end

      it 'returns http unprocessable entity' do
        expect(response.status).to eq(422)
      end
    end

    context 'given valid name param' do
      before do
        allow_any_instance_of(Action::PdamAutoswitch::Group::List).to receive(:run!).and_return autoswitch_group_relation
        allow_any_instance_of(autoswitch_group_relation.class).to receive_message_chain(:limit, :offset).and_return(autoswitch_groups)

        get :index, params: { name: 'test12' }
      end

      it 'returns http success' do
        result = JSON.parse(response.body)
        expect(result['data'].first).to include(*autoswitch_group_structure)

        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'GET #show' do
    let(:autoswitch_group) { build_stubbed(:pdam_autoswitch_group, :with_members) }

    context 'given valid param' do
      before do
        allow_any_instance_of(Action::PdamAutoswitch::Group::Show).to receive(:run!).and_return autoswitch_group

        get :show, params: { id: autoswitch_group.id }
      end

      it 'returns http success' do
        result = JSON.parse(response.body)
        expect(result['data']).to include(*autoswitch_group_structure)

        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end

    context 'given invalid param' do
      context 'given wrong id' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::Group::Show).to receive(:run!).and_raise Exceptions::AutoswitchGroupNotFound

          get :show, params: { id: autoswitch_group.id }
        end

        it 'returns http request not found' do
          expect(response.status).to eq(404)
          expect(JSON.parse(response.body)['errors'].first['message']).to eq 'Autoswitch Group Not Found'
        end
      end
    end
  end

  describe 'GET #create' do
    let(:autoswitch_group) { build_stubbed(:pdam_autoswitch_group, :with_members) }

    context 'given valid param' do
      before do
        allow_any_instance_of(Action::PdamAutoswitch::Group::Create).to receive(:run!).and_return autoswitch_group

        post :create, params: { name: 'Denpasar', state: 'active' }
      end

      it 'returns http success' do
        result = JSON.parse(response.body)
        expect(result['data']).to include(*autoswitch_group_structure)

        expect(response).to have_http_status(:created)
        expect(response.status).to eq(201)
      end
    end

    context 'given invalid param' do
      context 'given nil param' do
        before do
          post :create
        end

        it 'returns http uproceessed entity' do
          expect(response.status).to eq(422)
        end
      end

      context 'given empty param' do
        before do
          post :create, params: { name: '', state: 'active' }
        end

        it 'returns http uproceessed entity' do
          expect(response.status).to eq(422)
        end
      end
    end
  end

  describe 'GET #delete' do
    let(:autoswitch_group) { build_stubbed(:pdam_autoswitch_group, :with_members) }

    context 'given valid param' do
      context 'when autoswitch group found' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::Group::Delete).to receive(:run!).and_return true
          delete :delete, params: { id: autoswitch_group.id}
        end

        it 'returns http success' do
          expect(response).to have_http_status(:success)
          expect(response.status).to eq(200)
        end
      end

      context 'when autoswitch group not found' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::Group::Delete).to receive(:run!).and_raise Exceptions::AutoswitchGroupNotFound
          delete :delete, params: { id: autoswitch_group.id }
        end

        it 'returns http request not found' do
          expect(response.status).to eq(404)
          expect(JSON.parse(response.body)['errors'].first['message']).to eq 'Autoswitch Group Not Found'
        end
      end
    end
  end

  describe 'PATCH #update' do
    let(:autoswitch_group) { build_stubbed(:pdam_autoswitch_group, :with_members) }

    context 'given valid param' do
      context 'when autoswitch group found' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::Group::Update).to receive(:run!).and_return autoswitch_group
          patch :update, params: { id: autoswitch_group.id, name: 'Denpasar'}
        end

        it 'returns http success' do
          result = JSON.parse(response.body)
          expect(result['data']).to include(*autoswitch_group_structure)

          expect(response).to have_http_status(:success)
          expect(response.status).to eq(200)
        end
      end

      context 'when autoswitch group not found' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::Group::Update).to receive(:run!).and_raise Exceptions::AutoswitchGroupNotFound
          patch :update, params: { id: autoswitch_group.id, name: 'Denpasar'}
        end

        it 'returns http request not found' do
          expect(response.status).to eq(404)
          expect(JSON.parse(response.body)['errors'].first['message']).to eq 'Autoswitch Group Not Found'
        end
      end
    end

    context 'given invalid param' do
      context 'given nil param' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::Group::Update).to receive(:run!).and_return nil

          patch :update, params: { id: autoswitch_group.id }
        end

        it 'returns http uproceessed entity' do
          expect(response.status).to eq(422)
        end
      end

      context 'given empty param' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::Group::Update).to receive(:run!).and_return nil

          patch :update, params: { id: autoswitch_group.id, name: '' }
        end

        it 'returns http uproceessed entity' do
          expect(response.status).to eq(422)
        end
      end
    end
  end

  describe 'PATCH #status' do
    let(:autoswitch_group) { build_stubbed(:pdam_autoswitch_group, :with_members) }

    context 'given valid param' do
      context 'when autoswitch group found' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::Group::Status).to receive(:run!).and_return autoswitch_group
          patch :status, params: { id: autoswitch_group.id, state: 'active'}
        end

        it 'returns http success' do
          result = JSON.parse(response.body)
          expect(result['data']).to include(*autoswitch_group_structure)

          expect(response).to have_http_status(:success)
          expect(response.status).to eq(200)
        end
      end

      context 'when autoswitch group not found' do
        before do
          allow_any_instance_of(Action::PdamAutoswitch::Group::Status).to receive(:run!).and_raise Exceptions::AutoswitchGroupNotFound
          patch :status, params: { id: autoswitch_group.id, state: 'active'}
        end

        it 'returns http request not found' do
          expect(response.status).to eq(404)
          expect(JSON.parse(response.body)['errors'].first['message']).to eq 'Autoswitch Group Not Found'
        end
      end
    end

    context 'given invalid param' do
      before do
        allow_any_instance_of(Action::PdamAutoswitch::Group::Status).to receive(:run!).and_return nil

        patch :status, params: { id: autoswitch_group.id }
      end

      it 'returns http uproceessed entity' do
        expect(response.status).to eq(422)
      end
    end
  end
end
