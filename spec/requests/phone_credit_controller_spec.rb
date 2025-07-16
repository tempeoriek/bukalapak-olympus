require "rails_helper"

RSpec.describe PhoneCreditController, type: :controller do
  include AuthHelper
  let(:customer_number) { '081234000001' }
  let(:provider) { build_stubbed :phone_credit_provider }
  let(:provider_prefix) { build_stubbed :provider_prefix }
  let(:transaction){ build_stubbed(:phone_credit_postpaid_transaction, :pending)}
  let(:channel_response) {
    {
      customer_no: customer_number,
      customer_name: 'INDAH PRAWITA HAPSARI',
      reference_no: '2203267',
      bill_count: 1,
      bill_periode: '201801',
      bill_amount: 25000,
      admin_fee: 1000,
      total_amount: 26000,
    }
  }
  let(:expected_inquiry_response) {
    JSON.parse({
      customer_number: '081234000001',
      customer_name: 'INDXXXXXXXXXXXXXXXARI',
      reference_no: '2203267',
      outstanding_bill: 1,
      start_bill_period: '2018-01-01',
      end_bill_period: '2018-01-01',
      admin_charge: 0,
      penalty_fee: 0,
      amount: 26500,
      provider: {
        name: provider.provider,
        product_name: provider.product_name,
        logo_url: provider.logo_url
      },
      partner: {
        name: 'PT Sepulsa Teknologi Indonesia'
      }
    }.to_json)
  }

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow(ProviderPrefix).to receive(:find_by).with(prefix: customer_number[0..4]).and_return(nil)
    allow(ProviderPrefix).to receive(:find_by).with(prefix: customer_number[0..3]).and_return(provider_prefix)
    allow(PhoneCreditProvider).to receive(:find).and_return(provider)
    stub_const("#{described_class.to_s}::PCP_MAX_INQUIRY_ATTEMPT", 0)
    stub_const("#{described_class.to_s}::PCP_MAX_INQUIRY_ATTEMPT_NEXT_DAY_RESET_HOUR", 3)
  end

  describe 'POST #inquiries' do
    before do
      allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(channel_response)
    end

    context 'when user logged in' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false} })
        post :inquiries, params: { customer_number: customer_number }
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

    context 'when user is blacklisted' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false} })
        stub_const("#{described_class.to_s}::BLACKLIST_PCP_USER_IDS", '1,2,3')
        post :inquiries, params: { customer_number: customer_number }
      end

      it 'returns max inquiry attempt error' do
        expect(response.status).to eq(429)
      end
    end

    context 'when max inquiry attempt is set' do
      let(:redis_key) { "#{described_class::REDIS_KEY_INQUIRY_COUNTER_PREFIX}:1" }

      before {
        stub_const("#{described_class.to_s}::PCP_MAX_INQUIRY_ATTEMPT", 3)
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false} })
        allow(RedisOlympus).to receive(:expire).with(redis_key, any_args).and_return(true)
      }

      context 'when inquiry under max attempt' do
        before do
          allow(RedisOlympus).to receive(:incr).with(redis_key).and_return(1)
          post :inquiries, params: { customer_number: customer_number }
        end

        it 'returns 200' do
          expect(response.status).to eq(200)
        end
      end

      context 'when inquiry at max attempt' do
        before do
          allow(RedisOlympus).to receive(:incr).with(redis_key).and_return(3)
          post :inquiries, params: { customer_number: customer_number }
        end

        it 'returns 200' do
          expect(response.status).to eq(200)
        end
      end

      context 'when inquiry over max attempt' do
        before do
          allow(RedisOlympus).to receive(:incr).with(redis_key).and_return(4)
          post :inquiries, params: { customer_number: customer_number }
        end

        it 'returns max inquiry attempt error' do
          expect(response.status).to eq(429)
        end
      end

      context 'when whitelisted user inquiry over max attemp' do
        before do
          stub_const("#{described_class.to_s}::WHITELIST_LIMIT_PCP_USER_IDS", '1')
          allow(RedisOlympus).to receive(:incr).with(redis_key).and_return(4)
          post :inquiries, params: { customer_number: customer_number }
        end

        it 'returns 200' do
          expect(response.status).to eq(200)
        end
      end
    end

    context 'when user not logged in' do
      before do
        post :inquiries, params: { customer_number: customer_number }
      end

      it 'returns unauthorized error' do
        expect(response.status).to eq(401)
      end
    end
  end

  describe 'POST #create' do
    let(:expected_create_response) {
      JSON.parse({
        id: transaction.id,
        buyer_id: 1,
        type: 'phone-credit-postpaid',
        invoice_id: nil,
        remote_transaction_id: transaction.remote_transaction_id,
        customer_number: '081234000001',
        customer_name: 'INDAH PRAWITA HAPSARI',
        reference_no: '2203267',
        outstanding_bill: 1,
        admin_charge: 0,
        penalty_fee: 0,
        amount: 52500,
        start_bill_period: '2018-01-01',
        end_bill_period: '2018-01-01',
        state: 'pending',
        provider: {
          name: provider.provider,
          product_name: provider.product_name,
          logo_url: provider.logo_url
        },
        state_changed_at: {
          processed_at: nil,
          succeeded_at: nil,
          failed_at: nil
        },
        partner: {
          name: 'PT Sepulsa Teknologi Indonesia'
        },
        transaction_type: 'normal'
      }.to_json).with_indifferent_access
    }

    before do
      allow_any_instance_of(Action::PhoneCreditTransaction::Create).to receive(:run!).and_return(transaction)
      allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false} })
      post :create, params: { customer_number: customer_number }
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
      let(:transaction) { build_stubbed(:phone_credit_postpaid_transaction) }

      before do
        allow(PhoneCreditPostpaidTransaction).to receive(:find_by_id).and_return(transaction)
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
      allow(PhoneCreditPostpaidTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'transaction not present' do

      let(:transaction) { build_stubbed(:phone_credit_postpaid_transaction) }

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
      let(:transaction) { build_stubbed(:phone_credit_postpaid_transaction) }
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
      allow(PhoneCreditPostpaidTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'transaction not present' do

      let(:transaction) { build_stubbed(:phone_credit_postpaid_transaction) }

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
      let(:transaction) { build(:phone_credit_postpaid_transaction) }

      it 'returns http success' do
        post :invoicing, params: { id: 1,  invoice_id: 1 }
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'POST #confirm' do

    before do
      allow_any_instance_of(Authenticate).to receive(:http_basic_authenticate).and_return true
      allow(PhoneCreditPostpaidTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'transaction not present' do

      let(:transaction) { build_stubbed(:phone_credit_postpaid_transaction) }

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
      let(:transaction) { build(:phone_credit_postpaid_transaction) }

      it 'returns http success' do
        post :confirm, params: { id: 1 }
        expect(response.status).to eq(200)
      end
    end
  end
end
