require "rails_helper"

RSpec.describe Recurrence::Pdam::InternalController, type: :controller do
  include AuthHelper
  let(:recurrence_template) { create(:pdam_recurrence_template_detail) }
  let(:pdam_operator) { build_stubbed(:pdam_operator, :sepulsa) }
  let(:sepulsa_inquiry) { build(:sepulsa_response, :pdam_inquiry) }
  let(:expected_create_response) {
    {
      amount: 187000
    }
  }
  let(:deposit) {
    {
      withdrawable_balance: 40000
    }
  }
  let(:remote_id) {
    {
      id: 1
    }
  }

  let(:pdam_recurrence_template_detail) {
    build_stubbed(:pdam_recurrence_template_detail)
  }

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow_any_instance_of(Recurrence::Pdam::InternalController).to receive(:http_basic_authenticate).and_return true
    allow(::Toggle::PdamAutoswitch)
      .to receive(:active?)
      .and_return(true)
  end

  describe 'POST #create_transaction' do
    before do
      allow(PdamOperator).to receive(:find_by_id).with(recurrence_template.operator_id).and_return(pdam_operator)
      allow_any_instance_of(PdamTransaction).to receive(:operator).and_return(pdam_operator)
      allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(sepulsa_inquiry)
      allow_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return(remote_id)
      allow_any_instance_of(Escrow::RetrieveDeposit).to receive(:run!).and_return(deposit)
      post :create, params: { detail_id: recurrence_template.id }
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(201)
    end

    it 'returns correct json' do
      hash_body = nil
      expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
      expect(hash_body[:data]).to include(expected_create_response)
    end
  end

  describe 'POST #notify_balance' do
    let(:params) { { detail_id: recurrence_template.id, action_date: "2018-08-02" } }

    before do
      expect(Recurrence::Pdam::Notifier).to receive(:new).with('olympus_recurrence_topup_deposit_pdam_payload', params[:detail_id].to_s, { action_date: params[:action_date] }) do
        double = double('Recurrence::Pdam::Notifier')
        expect(double).to receive(:run!).and_return true
        double
      end

      post :notify_balance, params: { detail_id: recurrence_template.id, action_date: "2018-08-02" }
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(202)
    end
  end

  describe 'POST #notify_stop' do
    before do
      expect(Recurrence::Pdam::Notifier).to receive(:new).with('olympus_recurrence_unsubscribe_success_pdam_payload', recurrence_template.id.to_s) do
        double = double('Recurrence::Pdam::Notifier')
        expect(double).to receive(:run!).and_return true
        double
      end

      post :notify_stop, params: { detail_id: recurrence_template.id }
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(202)
    end
  end
end
