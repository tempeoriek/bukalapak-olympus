require "rails_helper"

RSpec.describe Recurrence::ElectricityPostpaid::TemplateDetailsController, type: :controller do
  include AuthHelper
  let(:recurrence_template) { create(:electricity_postpaid_recurrence_template_detail) }
  let(:partner_sepulsa) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }
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
  let(:create_params) {
    {
      customer_number: '512345610000',
      recurrence_value: '1',
      recurrence_type: 'on_date'
    }
  }
  let(:expected_create_response) {
    {
      customer_number: '512345610000',
      customer_name: 'SERTU SABARIYANTO',
      buyer_id: 1,
      recursive_id: 1
    }
  }
  let(:deposit) { { withdrawable_balance: 40000 } }
  let(:remote_id) {
    {
      id: 1
    }
  }
  let(:recursive_response) {
    {
      data: {
        id: 1
      },
      http_status: 201
    }.to_json
  }

  before do
    allow(ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1 })
    allow(Time.zone).to receive(:now).and_return(Time.parse("01:01"))
  end

  describe 'POST #create_transaction' do
    context 'Partner: Sepulsa' do
      before do
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
        allow(Channel::Connection::Http).to receive(:post).with(anything, anything, anything).and_return(recursive_response)
        allow_any_instance_of(Recurrence::ElectricityPostpaid::Notifier).to receive(:run!).and_return true
        allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return true
        allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
        post :create, params: {
          customer_number: '512345610000',
          recurrence_value: '1',
          recurrence_type: 'on_date'
        }
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

    context 'Partner: Bukopin' do
      before do
        allow(::ElectricityPostpaidPartner).to receive(:find_by).and_return build(:electricity_postpaid_partner, :bukopin)
        expect(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:new).with(create_params[:customer_number], buyer_type: RECURRENCE_ELIGIBLE_BUYER_TYPE).and_call_original
        expect_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:run!).and_return(inquiry_response)


        allow(Channel::Connection::Http).to receive(:post).with(anything, anything, anything).and_return(recursive_response)
        allow_any_instance_of(Recurrence::ElectricityPostpaid::Notifier).to receive(:run!).and_return true
        post :create, params: {
          customer_number: '512345610000',
          recurrence_value: '1',
          recurrence_type: 'on_date'
        }
      end

      let(:inquiry_response) {
          {
          :customer_number=>"512345600003",
          :customer_name=>"SERTU SABARIYANTO        ",
          :segmentation=>"  R1",
          :power=>1300,
          :stand_meter=>"00001111 - 00002222",
          :outstanding_bill=>1,
          :unpaid_bill=>0,
          :admin_charge=>2750,
          :amount=>300000,
          :reference_number=>"2FED321E2298361A198B6CB141138DBD",
          :info_text=>"",
          :response_code=>"0000",
          :stan=>123,
          :bill_status=>"1",
          :bills=>
          [{:bill_period=>"201807",
            :due_date=>"10072018",
            :meter_read_date=>"10072018",
            :total_electricity_bill=>"000000300000",
            :incentive=>"C0000000000",
            :value_added_tax=>"0000000000",
            :penalty_fee=>0,
            :previous_meter_reading=>"00001111",
            :current_meter_reading=>"00002222",
            :previous_meter_reading_2=>"00000008",
            :current_meter_reading_2=>"00000008",
            :previous_meter_reading_3=>"00000008",
            :current_meter_reading_3=>"00000008",
            :amount=>300000,
            :previous_meter=>"00001111",
            :current_meter=>"00002222"}],
          :status=>"success"
          }.to_h
      }

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


  end
end
  # describe 'POST #notify_balance' do
  #   before do
  #     allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
  #     allow_any_instance_of(Escrow::RetrieveDeposit).to receive(:run!).and_return(deposit)
  #     allow(Escrow::Connection).to receive(:post).with(anything, anything).and_return(true)
  #     post :notify_balance, params: { detail_id: recurrence_template.id, action_date: "2018-08-02" }
  #   end

  #   it 'returns http success' do
  #     expect(response).to have_http_status(:success)
  #     expect(response.status).to eq(202)
  #   end
  # end
