require 'rails_helper'
require 'examples/ayoconnect_examples'

RSpec.describe BpjsKetenagakerjaanController, type: :controller do
  include AuthHelper
  include_context 'ayoconnect_lets'

  let(:bpu_customer_number) { '1871010907930009' }
  let(:pu_customer_number) { '210800004501' }
  let(:register_transaction_response) { { id: 1 } }
  let(:partner_object) { build_stubbed(:bpjs_ketenagakerjaan_partner) }
  let(:payment_period) { 1 }
  let(:expected_inquiry_response) do
    JSON.parse({
      customer_number: '1871010907930009',
      customer_name: 'NI*O JU***N',
      bpjs_tk_type: 'bpu',
      branch_name: 'JAKARTA GROGOL',
      amount: 38_300,
      admin_charge: 1500,
      period: {
        total_month: 1,
        start_date: '2021-08-27',
        end_date: '2021-09-26'
      },
      partner: {
        name: 'PT. Ayopop Teknologi Indonesia'
      },
      bills: [{
        amount: 36_800,
        jht: 20_000,
        jkk: 10_000,
        jkm: 6800
      }],
      bill_code: 'N/A',
      division: nil,
      npp: nil,
      unpaid_bills: false
    }.to_json).with_indifferent_access
  end
  let(:expected_inquiry_unpaid_bills_response) do
    JSON.parse({
      customer_number: '1871010907930009',
      customer_name: 'NI*O JU***N',
      bpjs_tk_type: 'bpu',
      branch_name: 'JAKARTA GROGOL',
      amount: 38_300,
      admin_charge: 1500,
      period: {
        total_month: nil,
        start_date: '2021-08-27',
        end_date: '2021-09-26'
      },
      partner: {
        name: 'PT. Ayopop Teknologi Indonesia'
      },
      bills: [{
        amount: 36_800,
        jht: 20_000,
        jkk: 10_000,
        jkm: 6800
      }],
      bill_code: '921083112662',
      division: nil,
      npp: nil,
      unpaid_bills: true
    }.to_json).with_indifferent_access
  end
  let(:expected_create_bpu_response) do
    JSON.parse({
      buyer_id: 1,
      remote_transaction_id: 1,
      invoice_id: nil,
      reference_number: nil,
      state: 'pending',
      processed_at: nil,
      succeeded_at: nil,
      failed_at: nil,
      type: 'bpjs-ketenagakerjaan',
      image_url: 'https://s4.bukalapak.com/images/virtual_product/logo_bpjs_tk.jpg',
      transaction_type: 'agent',
      customer_number: '1871010907930009',
      customer_name: 'NI*O JU***N',
      bpjs_tk_type: 'bpu',
      branch_name: 'JAKARTA GROGOL',
      amount: 38_300,
      admin_charge: 1500,
      period: {
        total_month: 1,
        start_date: '2021-08-27',
        end_date: '2021-09-26'
      },
      partner: {
        name: 'PT. Ayopop Teknologi Indonesia'
      },
      bills: [{
        amount: 36_800,
        jht: 20_000,
        jkk: 10_000,
        jkm: 6800
      }],
      bill_code: 'N/A',
      division: nil,
      npp: nil,
      unpaid_bills: false
    }.to_json).with_indifferent_access
  end
  let(:expected_create_pu_response) do
    JSON.parse({
      buyer_id: 1,
      remote_transaction_id: 1,
      invoice_id: nil,
      reference_number: nil,
      state: 'pending',
      processed_at: nil,
      succeeded_at: nil,
      failed_at: nil,
      type: 'bpjs-ketenagakerjaan',
      image_url: 'https://s4.bukalapak.com/images/virtual_product/logo_bpjs_tk.jpg',
      transaction_type: 'agent',
      customer_number: '210800004501',
      customer_name: 'JKP EMPAT',
      bpjs_tk_type: 'pu',
      branch_name: nil,
      amount: 110_490,
      admin_charge: 1500,
      period: {
        total_month: 1,
        start_date: '2021-09-01',
        end_date: '2021-09-30'
      },
      partner: {
        name: 'PT. Ayopop Teknologi Indonesia'
      },
      bills: [{
        amount: 108_990,
        jht: 63_167,
        jkk: 17_269,
        jkm: 3787,
        jkp: 0,
        jp: 24_767
      }],
      bill_code: nil,
      division: '000',
      npp: '21000104',
      unpaid_bills: false
    }.to_json).with_indifferent_access
  end
  let(:decoded_token) do
    {
      resource_owner_id: 1,
      resource_owner: {
        agent: false,
        o2o_agent: {
          status: 'confirmed'
        }
      }
    }
  end

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow(BpjsKetenagakerjaanPartner).to receive(:find_by).and_return partner_object
    allow_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return(register_transaction_response)
  end

  describe '#inquiries' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: { agent: false, o2o_agent: { status: 'confirmed' } } })
      allow_any_instance_of(Channel::Ayoconnect::Base).to receive(:inquiry).and_return(valid_bpjs_ketenagakerjaan_bpu_inquiry_response)
      allow(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect).to receive(:active?).and_return(false)
      post :inquiries, params: { customer_number: bpu_customer_number, payment_period: payment_period }
    end

    context 'when no unpaid bills' do
      before do
        allow_any_instance_of(Channel::Ayoconnect::Base).to receive(:inquiry).and_return(valid_bpjs_ketenagakerjaan_bpu_inquiry_response)
        post :inquiries, params: { customer_number: bpu_customer_number, payment_period: payment_period }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to match(expected_inquiry_response)
      end
    end

    context 'when has an unpaid bills' do
      before do
        allow_any_instance_of(Channel::Ayoconnect::Base).to receive(:inquiry).and_return(valid_bpjs_ketenagakerjaan_bpu_inquiry_response_with_tunggakan)
        post :inquiries, params: { customer_number: bpu_customer_number, payment_period: payment_period }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to match(expected_inquiry_unpaid_bills_response)
      end
    end
  end

  describe '#create' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: { agent: false, o2o_agent: { status: 'confirmed' } } })
      allow(::Toggle::CircuitBreaker::ElectricityPostpaid::Ayoconnect).to receive(:active?).and_return(false)
    end

    context 'when bpjs tk type is bpu' do
      before do
        allow_any_instance_of(Channel::Ayoconnect::Base).to receive(:inquiry).and_return(valid_bpjs_ketenagakerjaan_bpu_inquiry_response)
        post :create, params: { customer_number: bpu_customer_number, payment_period: payment_period }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(201)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to include(expected_create_bpu_response)
      end
    end

    context 'when bpjs tk type is pu' do
      before do
        allow_any_instance_of(Channel::Ayoconnect::Base).to receive(:inquiry).and_return(valid_bpjs_ketenagakerjaan_pu_inquiry_response)
        post :create, params: { customer_number: pu_customer_number, payment_period: payment_period }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(201)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to include(expected_create_pu_response)
      end
    end
  end

  describe 'O2OVPD-927: GET #show' do
    context 'transaction not present' do
      it 'returns transaction not found' do
        get :show, params: { id: 1 }
        expect(JSON.parse(response.body)['errors'][0]['code']).to eq(18_108)
        expect(response.status).to eq(404)
      end
    end

    context 'transaction present' do
      let(:transaction) { build_stubbed(:bpjs_ketenagakerjaan_transaction) }

      before do
        allow(BpjsKetenagakerjaanTransaction).to receive(:find_by_id).and_return(transaction)
      end

      it 'returns http unauthorized' do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner: { role: 'normal' } })
        get :show, params: { id: 1 }
        expect(JSON.parse(response.body)['errors'][0]['code']).to eq(18_107)
        expect(response.status).to eq(401)
      end

      it 'returns http success for sales' do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner: { role: 'sales' } })
        get :show, params: { id: 1 }
        expect(response.status).to eq(200)
      end

      it 'returns http success for disbursement' do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner: { role: 'disbursement' } })
        get :show, params: { id: 1 }
        expect(response.status).to eq(200)
      end

      it 'returns a buyer_id info' do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner: { role: 'disbursement' } })
        get :show, params: { id: 1 }
        expect(JSON.parse(response.body).with_indifferent_access[:data][:buyer_id]).not_to eq nil
      end
    end
  end

  describe 'O2OVPD-884: GET #get_receipt' do
    before do
      expect(JsonWebToken).to receive(:decode).and_return(decoded_token)
      allow(BpjsKetenagakerjaanTransaction).to receive(:find_by_id).and_return(transaction)
    end

    context 'when unauthorized user' do
      let(:transaction) { build_stubbed(:bpjs_ketenagakerjaan_transaction) }

      before do
        allow(transaction).to receive(:buyer_id).and_return 123
      end

      it 'returns 401 unauthorized' do
        get :get_receipt, params: { id: 1, type: 'png' }
        expect(JSON.parse(response.body)['errors'][0]['code']).to eq(18_107)
        expect(response.status).to eq(401)
      end
    end

    context 'when success response' do
      let(:transaction) { create(:bpjs_ketenagakerjaan_transaction) }
      let(:expected_receipt_response) do
        {
          data: {
            page_body: 'image string'
          },
          meta: {
            http_status: 200
          }
        }.to_json
      end
      let(:result) { 'image string' }

      before { expect_any_instance_of(Action::PostpaidTransaction::GetReceipt).to receive(:run!) { result } }

      context 'when type is png' do
        it 'returns http success' do
          get :get_receipt, params: { id: 1, type: 'png' }
          expect(response.status).to eq(200)
          expect(response.body).to eq(expected_receipt_response)
        end
      end

      context 'when type is pdf' do
        let(:result) do
          {
            pdf: 'text',
            filename: 'BUKTI_BAYAR_123.pdf'
          }
        end
        it 'calls send_data' do
          expect_any_instance_of(described_class).to receive(:send_data).with(kind_of(String), filename: kind_of(String), type: 'application/pdf')
          get :get_receipt, params: { id: 1, type: 'pdf' }
        end
      end
    end
  end
end
