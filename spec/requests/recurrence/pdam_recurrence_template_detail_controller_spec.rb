require "rails_helper"

RSpec.describe Recurrence::Pdam::TemplateDetailsController, type: :controller do
  include AuthHelper
  let(:recurrence_template) { create(:pdam_recurrence_template_detail) }
  let(:pdam_operator) { build_stubbed(:pdam_operator, :sepulsa) }
  let(:inquiry_response) {
    {
      idpel: '1998900001',
      name: 'JUNAIDI XX001                 ',
      amount: 11110,
      admin_charge: 0,
      blth: "201201201201",
      bill_count: '01',
      bill_repeat_count: '01',
      bills: [
        {
          bill_date: ['201201'],
          bill_amount: ['000000011110'],
          penalty: ["00000000"],
          kubikasi: ["00000402-00000458"]
        }
      ]
    }
  }
  let(:create_params) {
    {
      customer_number: '1998900001',
      operator_id: 1,
      recurrence_value: '1',
      recurrence_type: 'on_date'
    }
  }
  let(:expected_create_response) {
    {
      customer_number: '1998900001',
      customer_name: 'JUNAIDI XX001',
      operator_id: 1,
      buyer_id: 1,
      recursive_id: 1
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
  let(:recursive_response) {
    {
      data: {
        id: 1
      },
      http_status: 201
    }.to_json
  }

  before do
    allow(PdamOperator).to receive(:find_by).with(id: recurrence_template.operator_id).and_return(pdam_operator)
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow_any_instance_of(Recurrence::Pdam::Notifier).to receive(:run!).and_return true
    allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1 })
    allow(::Toggle::PdamAutoswitch).to receive(:active?).and_return(true)
  end

  describe 'POST #create_transaction' do
    before do
      allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
      allow(Channel::Connection::Http).to receive(:post).with(anything, anything, anything).and_return(recursive_response)
      post :create, params: {
        customer_number: '1998900001',
        operator_id: 1,
        recurrence_value: '1',
        recurrence_type: 'on_date'
      }, as: :json
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
end
