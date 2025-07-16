require 'rails_helper'

RSpec.describe BpjsKesehatanController, type: :controller do
  include AuthHelper
  let(:customer_number) { '0000001430071801' }
  let(:transaction) { build_stubbed(:bpjs_kesehatan_transaction) }
  let(:partner_object) { build_stubbed(:bpjs_kesehatan_partner) }
  let(:payment_period) { '01' }
  let(:month) { transaction.month }
  let(:year) { transaction.year }
  let(:paid_until) {
    {
      month: month,
      year: year
    }
  }
  let(:inquiry_response) {
    {
      name: 'ANISA KARTIKA INDIARTI (PST:  1)',
      no_va: '0000001430071801',
      nama_cabang: 'SEMARANG',
      premi: '51000',
      periode: '01',
      paid_until: '2017-10'
    }
  }
  let(:expected_inquiry_response) {
    JSON.parse({
      customer_number: '0000001430071801',
      customer_name: 'ANISA KARTIKA INDIARTI',
      branch_name: 'SEMARANG',
      family_members: [],
      family_member_count: 1,
      amount: 52500,
      admin_charge: 1500,
      paid_until: {month: month, year: year},
      payment_period: '01',
      partner: {
        name: 'PT Sepulsa Teknologi Indonesia'
      }
    }.to_json).with_indifferent_access
  }
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
    allow(BpjsKesehatanPartner).to receive(:find_by).and_return partner_object
    allow(Time).to receive(:now).and_return(Time.new(2017,8,12))
  end

  describe 'POST #inquiries' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false, o2o_agent: {status: 'confirmed'}}})
      allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
      allow(::Toggle::CircuitBreaker::BpjsKesehatan::Sepulsa).to receive(:active?).and_return(false)
      post :inquiries, params: { customer_number: customer_number, paid_until: paid_until }
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

  describe 'POST #create' do
    let(:expected_create_response) {
      JSON.parse({
        id: transaction.id,
        customer_number: '0000001430071801',
        customer_name: 'NISA KARTIKA INDIARTI',
        amount: 51000,
        branch_name: 'SEMARANG',
        buyer_id: 1,
        family_member_count: 1,
        family_members:  [
          {
            id: nil,
            member_number: "123814123",
            name: "Prengki",
            premium: 55000,
            balance: 0
          }
        ],
        paid_until: {month: month, year: year},
        payment_period: '01',
        state: 'pending',
        invoice_id: 1,
        remote_transaction_id: 1,
        admin_charge: 1500,
        type: 'bpjs-kesehatan',
        image_url: 'https://s4.bukalapak.com/images/virtual_product/logo_bpjs.png',
        info: nil,
        reference_number: nil,
        partner: {
          name: 'PT Sepulsa Teknologi Indonesia'
        },
        transaction_type: 'normal'
      }.to_json).with_indifferent_access
    }

    before do
      allow_any_instance_of(Action::BpjsKesehatanTransaction::Create).to receive(:run!).and_return(transaction)
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false}})
      post :create, params: { customer_number: customer_number, paid_until: paid_until }
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(201)
    end

    it 'returns correct json' do
      hash_body = nil
      expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
      expect(hash_body[:data]).to match(expected_create_response)
    end
  end

  describe 'GET #show' do
    before do
      allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
      allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    end
    context 'transaction not present' do
      it 'returns transaction not found' do
        get :show, params: { id: 1 }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18108)
        expect(response.status).to eq(404)
      end
    end

    context 'transaction present' do
      let(:transaction) { build_stubbed(:bpjs_kesehatan_transaction) }

      before do
        allow(BpjsKesehatanTransaction).to receive(:find_by_id).and_return(transaction)
      end

      it 'returns http unauthorized' do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner: { role: 'normal'}})
        get :show, params: { id: 1 }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
        expect(response.status).to eq(401)
      end

      it 'returns http success for sales' do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner: { role: 'sales'}})
        get :show, params: { id: 1 }
        expect(response.status).to eq(200)
      end

      it 'returns http success for disbursement' do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner: { role: 'disbursement'}})
        get :show, params: { id: 1 }
        expect(response.status).to eq(200)
      end

      it 'returns a buyer_id info' do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner: { role: 'disbursement'}})
        get :show, params: { id: 1 }
        expect(JSON.parse(response.body).with_indifferent_access[:data][:buyer_id]).not_to eq nil
      end
    end
  end

  describe 'POST #Pay' do

    before do
      allow_any_instance_of(Authenticate).to receive(:http_basic_authenticate).and_return true
      allow(BpjsKesehatanTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'transaction not present' do

      let(:transaction) { build_stubbed(:bpjs_kesehatan_transaction) }

      it 'returns transaction not found' do
        allow(transaction).to receive(:present?).and_return(false)
        post :pay, params: { id: 1 }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18108)
        expect(response.status).to eq(404)
      end
    end

    context 'transaction present' do

      before do
        allow(transaction).to receive(:present?).and_return(true)
        expect(Action::PostpaidTransaction::Process).to receive(:new).with(transaction, payment_id) { mock_postpaid }
        allow(mock_postpaid).to receive(:run!)
      end

      let(:mock_postpaid) { instance_double(Action::PostpaidTransaction::Process) }
      let(:transaction) { build_stubbed(:bpjs_kesehatan_transaction) }
      let(:payment_id) { "BL190102ABCDEINV" }

      it 'returns http success' do
        post :pay, params: { id: 1, payment_id: payment_id }
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'POST #invoicing' do

    before do
      allow_any_instance_of(Authenticate).to receive(:http_basic_authenticate).and_return true
      allow(BpjsKesehatanTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'transaction not present' do

      let(:transaction) { build_stubbed(:bpjs_kesehatan_transaction) }

      it 'returns transaction not found' do
        allow(transaction).to receive(:present?).and_return(false)
        post :invoicing, params: { id: 1, invoice_id: 1 }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18108)
        expect(response.status).to eq(404)
      end
    end

    context 'transaction present' do

      before do
        allow(transaction).to receive(:present?).and_return(true)
        expect(Action::PostpaidTransaction::Invoicing).to receive(:new).with(transaction, "1") { mock_postpaid }
        allow(mock_postpaid).to receive(:run!)
      end

      let(:mock_postpaid) { instance_double(Action::PostpaidTransaction::Invoicing) }
      let(:transaction) { build(:bpjs_kesehatan_transaction) }

      it 'returns http success' do
        post :invoicing, params: { id: 1,  invoice_id: 1 }
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'POST #confirm' do

    before do
      allow_any_instance_of(Authenticate).to receive(:http_basic_authenticate).and_return true
      allow(BpjsKesehatanTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'transaction not present' do

      let(:transaction) { build_stubbed(:bpjs_kesehatan_transaction) }

      it 'returns transaction not found' do
        allow(transaction).to receive(:present?).and_return(false)
        post :confirm, params: { id: 1 }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18108)
        expect(response.status).to eq(404)
      end
    end

    context 'transaction present' do

      before do
        allow(transaction).to receive(:present?).and_return(true)
        expect(Action::PostpaidTransaction::ManualConfirm).to receive(:new).with(transaction) { mock_postpaid }
        allow(mock_postpaid).to receive(:run!)
      end

      let(:mock_postpaid) { instance_double(Action::PostpaidTransaction::ManualConfirm) }
      let(:transaction) { build(:bpjs_kesehatan_transaction) }

      it 'returns http success' do
        post :confirm, params: { id: 1 }
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'GET #get_receipt' do
    before do
      expect(JsonWebToken).to receive(:decode).and_return(decoded_token)
      allow(BpjsKesehatanTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'unauthorized user' do

      let(:transaction) { build_stubbed(:bpjs_kesehatan_transaction) }

      before do
        allow(transaction).to receive(:buyer_id).and_return 123
      end

      it 'returns 401 unauthorized' do
        get :get_receipt, params: { id: 1, type: 'png' }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
        expect(response.status).to eq(401)
      end
    end

    context 'when response is ok' do
      let(:transaction) { create(:bpjs_kesehatan_transaction, :partner_succeeded, :with_paid_at, :with_info, buyer_id: 1) }
      let(:expected_receipt_response) {
        {
          data: {
            page_body: 'image string'
          },
          meta: {
            http_status: 200
          }
        }.to_json
      }
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
        let(:result) {
          {
            pdf: 'text',
            filename: "BUKTI_BAYAR_123.pdf"
          }
        }
        it 'calls send_data' do
          expect_any_instance_of(described_class).to receive(:send_data).with(kind_of(String), filename: kind_of(String), type: 'application/pdf')
          get :get_receipt, params: { id: 1, type: 'pdf' }
        end
      end
    end
  end
end
