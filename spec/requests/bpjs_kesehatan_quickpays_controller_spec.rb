require "rails_helper"

RSpec.describe BpjsKesehatanQuickpaysController, type: :controller do
  include Response::Quickpay

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
  end

  describe "GET #index" do
    context 'unauthorized' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false} })
      end

      it do
        get :index, params: { }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
        expect(response.status).to eq(401)
      end
    end

    context 'if agent' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: true} })
      end

      it do
        get :index, params: { }
        expect(response.status).to eq(200)
      end
    end

    context 'if non-agent ' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false} })
        allow(Quickpays::Get).to receive_message_chain(:new, :run!) { mock_quickpay }
        allow(Quickpays::Inquiry).to receive_message_chain(:new, :run!) { mock_quick_inq }
      end

        let(:mock_quickpay) { instance_double(Quickpays::Get) }
        let(:mock_quick_inq) { instance_double(Quickpays::Inquiry) }
      it do
        get :index, params: { skip_cache: true }
        expect(response.status).to eq(200)
      end
    end
  end

  describe "DELETE #delete" do
    context 'unauthorized' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 0, resource_owner: {agent: false} })
      end

      it do
        delete :delete
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
        expect(response.status).to eq(401)
      end
    end

    context 'authorized' do 
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false} })
      end

      it do
        delete :delete, params: {  }
        expect(response.status).to eq(200) 
      end
    end
    
  end

end