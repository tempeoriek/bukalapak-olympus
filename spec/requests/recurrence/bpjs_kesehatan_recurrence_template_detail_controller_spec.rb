require "rails_helper"

RSpec.describe Recurrence::BpjsKesehatan::TemplateDetailsController, type: :controller do
  include AuthHelper
  let(:recurrence_template) { create(:bpjs_kesehatan_recurrence_template_detail) }
  let(:partner_sepulsa) { build_stubbed(:bpjs_kesehatan_partner) }
  let(:deposit) { { withdrawable_balance: 40000 } }
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
      customer_number: '0000001430071801',
      customer_name: 'SEPULSAWATI',
      buyer_id: 1,
      recursive_id: 1
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
    allow(BpjsKesehatanPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: { phone: '082162505050' } })
  end

  describe 'POST #create_transaction' do
    let(:response) {
      post :create, params: {
        customer_number: '0000001430071801',
        recurrence_value: '1',
        recurrence_type: 'on_date'
      }
    }
    before do
      allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
      allow(Channel::Connection::Http).to receive(:post).with(anything, anything, anything).and_return(recursive_response)
      allow_any_instance_of(Recurrence::BpjsKesehatan::Notifier).to receive(:run!).and_return true
      allow(::Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa).to receive(:active?).and_return(false)
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

    context 'when one of required params is nil' do
      let(:response) {
        post :create, params: {
          customer_number: '0000001430071801',
          recurrence_value: '1',
          recurrence_type: nil
        }
      }
      it {
        expect(response.status).to eq(422)
      }
    end
  end
end
