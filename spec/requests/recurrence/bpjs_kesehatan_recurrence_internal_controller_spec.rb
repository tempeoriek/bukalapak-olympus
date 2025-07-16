require "rails_helper"

RSpec.describe Recurrence::BpjsKesehatan::InternalController, type: :controller do
  include AuthHelper
  let(:recurrence_template) { create(:bpjs_kesehatan_recurrence_template_detail) }
  let(:partner_sepulsa) { build_stubbed(:bpjs_kesehatan_partner) }
  let(:inquiry_response) {
    {
      name: 'SEPULSAWATI (PST:  2)',
      premi: 51000,
      no_va: '0000001430071801',
      periode: '01',
      nama_cabang: 'SEMARANG'
    }
  }
  let(:expected_create_response) {
    {
      amount: 52500
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
  let(:bpjs_kesehatan_recurrence_template_detail) {
    template_detail = build_stubbed(:bpjs_kesehatan_recurrence_template_detail)
    template_detail.buyer_id = remote_id
    template_detail
  }

  before do
    allow(BpjsKesehatanPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow_any_instance_of(Recurrence::BpjsKesehatan::InternalController).to receive(:http_basic_authenticate).and_return true
  end

  describe 'POST #create_transaction' do
    before do
      allow(BpjsKesehatanRecurrenceTemplateDetail).to receive(:find_by_id).and_return(recurrence_template)
      allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
      allow_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return(remote_id)
      allow_any_instance_of(Escrow::RetrieveDeposit).to receive(:run!).and_return(deposit)
      allow_any_instance_of(Recurrence::BpjsKesehatan::Notifier).to receive(:run!).and_return true
      allow(::Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa).to receive(:active?).and_return(false)
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
      expect(Recurrence::BpjsKesehatan::Notifier).to receive(:new).with('olympus_recurrence_topup_deposit_bpjs_kesehatan_payload', params[:detail_id].to_s, { action_date: params[:action_date] }) do
        double = double('Recurrence::BpjsKesehatan::Notifier')
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
      expect(Recurrence::BpjsKesehatan::Notifier).to receive(:new).with('olympus_recurrence_unsubscribe_success_bpjs_kesehatan_payload', recurrence_template.id.to_s) do
        double = double('Recurrence::BpjsKesehatan::Notifier')
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
