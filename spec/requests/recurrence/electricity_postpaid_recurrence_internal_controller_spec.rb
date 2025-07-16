require "rails_helper"

RSpec.describe Recurrence::ElectricityPostpaid::InternalController, type: :controller do
  include AuthHelper
  let(:recurrence_template) { create(:electricity_postpaid_recurrence_template_detail) }
  let(:partner_sepulsa) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }
  let(:user_deposit_data) { { withdrawable_balance: 100000 } }
  let(:inquiry_response) {
    {
      subscriber_id: '512345610000',
      subscriber_name: 'SERTU SABARIYANTO',
      subscriber_segmentation: 'R1',
      power: '900',
      stand_meter_summary: '00017822 - 00017915',
      bill_status: '1',
      bills: [
        {
          bill_period: '201103',
          due_date: '20110320',
          penalty_fee: '3500',
          total_electricity_bill: '20500',
          previous_meter_reading1: '00017822',
          current_meter_reading1: '00017915'
        },
        {
          bill_period: '201104',
          due_date: '20110420',
          penalty_fee: '7500',
          total_electricity_bill: '20000',
          previous_meter_reading1: '00017822',
          current_meter_reading1: '00017915'
        }
      ]
    }
  }
  let(:expected_create_response) {
    {
      amount: 54500
    }
  }
  let(:remote_id) {
    {
      id: 1
    }
  }

  before do
    allow(ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow_any_instance_of(Recurrence::ElectricityPostpaid::InternalController).to receive(:http_basic_authenticate).and_return true
    allow(Time.zone).to receive(:now).and_return(Time.parse("01:01"))
    allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return true
    allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
  end

  describe 'POST #create_transaction' do
    before do
      allow(ElectricityPostpaidRecurrenceTemplateDetail).to receive(:find_by_id).and_return(recurrence_template)
      allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
      allow_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return(remote_id)
      allow_any_instance_of(Escrow::RetrieveDeposit).to receive(:run!).and_return(user_deposit_data)
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
      expect(Recurrence::ElectricityPostpaid::Notifier).to receive(:new).with('olympus_recurrence_topup_deposit_postpaid_electricity_payload', params[:detail_id].to_s, { action_date: params[:action_date] }) do
        double = double('Recurrence::ElectricityPostpaid::Notifier')
        expect(double).to receive(:run!).and_return true
        double
      end

      post :notify_balance, params: params
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(202)
    end
  end

  describe 'POST #notify_stop' do
    before do
      expect(Recurrence::ElectricityPostpaid::Notifier).to receive(:new).with('olympus_recurrence_unsubscribe_success_postpaid_electricity_payload', recurrence_template.id.to_s) do
        double = double('Recurrence::ElectricityPostpaid::Notifier')
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
