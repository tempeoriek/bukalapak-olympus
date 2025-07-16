require "rails_helper"

RSpec.describe CreditCardBillController, type: :controller do
  include AuthHelper

  let(:transaction){ build(:cc_transaction)}
  let(:credit_card_biller) { transaction.credit_card_biller }
  let(:biller_id) { credit_card_biller.id }
  let(:remote_id) { { id: 1 } }
  let(:customer_number) { '4665730000000117' }
  let(:bni_inquiry_response) {
    {
      "error": false,
      "ket": "Kartu Kredit BNI",
      "cardNum": "4665730000000117",
      "statementDate": "11102012",
      "dueDate": "12102012",
      "cardHolder": "GA SIGN 2",
      "cardlinkFlag": "02",
      "lastBillAmountSign": "+",
      "lastBillAmount": "2000000",
      "minPayment": "100000",
      "minPayment1": "00000000",
      "minPayment2": "100000",
      "status": "2"
    }.to_json
  }

  let(:expected_inquiry_response) {
    {
      customer_number: '4665-73XX-XXXX-0117',
      customer_name: 'GA XXXN 2',
      amount: 2000000,
      admin_charge: credit_card_biller.admin_charge,
      minimum_payment: 100000,
      statement_date: '2012-10-11',
      due_date: '2012-10-12',
      biller: {
        id: credit_card_biller.id,
        name: credit_card_biller.name,
        image_url: credit_card_biller.image_url
      },
      partner: {
        name: "PT BNI Tbk"
      }
    }.with_indifferent_access
  }

  let(:expected_dbs_inquiry_response) {
    {
      customer_number: '4665-73XX-XXXX-0117',
      amount: 0,
      admin_charge: credit_card_biller.admin_charge,
      minimum_payment: CreditCardBillTransaction::MINIMUM_BASE_AMOUNT,
      biller: {
        id: credit_card_biller.id,
        name: credit_card_biller.name,
        image_url: credit_card_biller.image_url
      },
      partner: {
        name: "PT Bank DBS Indonesia"
      }
    }.with_indifferent_access
  }

  let(:expected_visa_inquiry_response) {
    {
      customer_number: '4665-73XX-XXXX-0117',
      amount: 0,
      admin_charge: credit_card_biller.admin_charge,
      minimum_payment: CreditCardBillTransaction::MINIMUM_BASE_AMOUNT,
      biller: {
        id: credit_card_biller.id,
        name: credit_card_biller.name,
        image_url: credit_card_biller.image_url
      },
      partner: {
        name: "PT Bank CIMB Niaga"
      }
    }.with_indifferent_access
  }

  let(:pay_amount) { 100000 }

  let(:expected_create_response) {
    {
      buyer_id: 1,
      invoice_id: transaction.invoice_id,
      remote_transaction_id: 1,
      state: "pending",
      customer_number: customer_number,
      customer_name: expected_inquiry_response["customer_name"],
      amount: pay_amount,
      minimum_payment: expected_inquiry_response["minimum_payment"],
      statement_date: expected_inquiry_response["statement_date"],
      due_date: expected_inquiry_response["due_date"],
      biller: {
        id: credit_card_biller.id,
        name: credit_card_biller.name,
        image_url: credit_card_biller.image_url
      },
      admin_charge: credit_card_biller.admin_charge,
      state_changed_at: {
        processed_at: nil,
        succeeded_at: nil,
        failed_at: nil
      },
      type: 'credit-card-bill',
      transaction_type: 'user',
      partner: {
        name: "PT BNI Tbk"
      }
    }.with_indifferent_access
  }

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return(remote_id)
    allow_any_instance_of(CreditCardBillTransaction).to receive(:biller).and_return(transaction.biller)
    allow_any_instance_of(CreditCardBillTransaction).to receive(:partner).and_return(transaction.partner)
    allow(Config::GeneralCircuitBreaker).to receive(:config).and_return(credit_card_bill: GeneralCircuitBreaker::CreditCardBill::CONFIG)
    allow(GeneralCircuitBreaker::CreditCardBill.instance).to receive(:allow?).and_return true
    allow(Toggles::CreditCardBill).to receive(:active?).and_return true
    allow(Toggles::WhitelistBni).to receive(:active?).and_return false
    allow(Toggles::WhitelistVisa).to receive(:active?).and_return false
    allow(::Toggle::CreditCardBill::WhitelistNewBNI).to receive(:active?).and_return(false)
    allow(Toggle::CreditCardBill::NewBNI).to receive(:active?).and_return false

    allow_any_instance_of(::Redis).to receive(:get).and_return 'this is you token! happy?!'
    allow_any_instance_of(::Redis).to receive(:incr).and_return 1

    # allow(CreditCardBiller).to receive(:where).with(active: true).and_return([credit_card_biller, credit_card_biller])
    allow(CreditCardBiller).to receive(:find).and_return(credit_card_biller)
    allow(Channel::Connection::Http).to receive(:post).and_return(bni_inquiry_response)
    allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: { agent: 0 } })
    allow(Time).to receive(:now).and_return(Time.new(2017,8,12))
  end

  describe 'GET #billers' do

    it 'returns http success' do
      get :billers
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(200)
    end

    it 'returns http error (PostpaidError)' do
      expect(CreditCardBiller).to receive(:where).with(active: true).and_raise Exceptions::PostpaidError
      get :billers
      expect(response.status).to eq 422
    end

    context 'when toggle off' do
      it {
        allow(Toggles::CreditCardBill).to receive(:active?).and_return false
        get :billers
        expect(response.status).to eq 422
      }
    end

    context 'O2OVPE-483: when circuit breaker is broken' do
      it {
        allow(GeneralCircuitBreaker::CreditCardBill.instance).to receive(:allow?).and_return false
        get :billers
        expect(response.status).to eq 422
      }
    end
  end

  describe 'POST #inquiries' do
    context 'when toggle on' do
      before do
        post :inquiries, params: { customer_number: customer_number, biller_id: biller_id }
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

      context 'with biller from partner dbs' do
        let(:credit_card_biller) { create(:credit_card_biller, :partner_pnl) }

        it 'return without inquirying to partner' do
          hash_body = JSON.parse(response.body).with_indifferent_access
          expect(response).to have_http_status(:success)
          expect(response.status).to eq(200)
          expect(hash_body[:data]).to match(expected_dbs_inquiry_response)
        end
      end

      context 'with biller from partner visa' do
        let(:credit_card_biller) { create(:credit_card_biller, :partner_visa) }

        it 'return without inquirying to partner' do
          hash_body = JSON.parse(response.body).with_indifferent_access
          expect(response).to have_http_status(:success)
          expect(response.status).to eq(200)
          expect(hash_body[:data]).to match(expected_visa_inquiry_response)
        end
      end

      context 'with biller from partner cimbniaga_thor' do
        let(:credit_card_biller) { create(:credit_card_biller, :cimbniaga_thor, :partner_cimbniaga_thor) }

        it 'return without inquirying to partner' do
          hash_body = JSON.parse(response.body).with_indifferent_access
          expect(response).to have_http_status(:success)
          expect(response.status).to eq(200)
          expect(hash_body[:data]).to match(expected_visa_inquiry_response)
        end
      end
    end

    context 'when toggle off' do
      it {
        allow(Toggles::CreditCardBill).to receive(:active?).and_return false
        post :inquiries, params: { customer_number: customer_number, biller_id: biller_id }
        expect(response.status).to eq 422
      }
    end

    context 'O2OVPE-483: when circuit breaker is broken' do
      it {
        allow(GeneralCircuitBreaker::CreditCardBill.instance).to receive(:allow?).and_return false
        post :inquiries, params: { customer_number: customer_number, biller_id: biller_id }
        expect(response.status).to eq 422
      }
    end
  end

  describe 'POST #create' do
    context 'when toggle on' do
      before do
        post :create, params: { customer_number: customer_number, biller_id: biller_id, amount: pay_amount }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(201)
      end

      it 'returns correct json' do
        hash_body = JSON.parse(response.body).with_indifferent_access
        data = hash_body[:data].merge({
          "id" => transaction.id,
          "invoice_id" => transaction.invoice_id,
        })
        expect(data).to include(expected_create_response)
      end
    end

    context 'when toggle off' do
      it {
        allow(Toggles::CreditCardBill).to receive(:active?).and_return false
        post :create, params: { customer_number: customer_number, biller_id: biller_id, amount: pay_amount }
        expect(response.status).to eq 422
      }

    end

    context 'O2OVPE-483: when circuit breaker is broken' do
      it {
        allow(GeneralCircuitBreaker::CreditCardBill.instance).to receive(:allow?).and_return false
        post :create, params: { customer_number: customer_number, biller_id: biller_id, amount: pay_amount }
        expect(response.status).to eq 422
      }
    end

    context 'when max amount exceeded' do
      it {
        post :create, params: { customer_number: customer_number, biller_id: biller_id, amount: 50_000_001 }
        expect(response.status).to eq 422
      }
    end

    context 'when create trx exceed limit' do
      it {
        allow(::RedisOlympus).to receive(:get).and_return 2
        stub_const("#{described_class.to_s}::CC_LIMIT_CREATE_TRX_ACTIVE", 'true')
        post :create, params: { customer_number: customer_number, biller_id: biller_id, amount: pay_amount }
        expect(response.status).to eq 422
      }
    end
  end

  describe 'GET #show' do
    context 'transaction not present' do
      it 'returns transaction not found' do
        get :show, params: { id: 1 }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18108)
        expect(response.status).to eq(404)
      end
    end

    context 'transaction present' do
      let(:transaction) { build_stubbed(:cc_transaction) }

      before do
        allow(CreditCardBillTransaction).to receive(:find_by_id).and_return(transaction)
      end

      it 'returns http unauthorized' do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner: { role: 'normal'}})
        get :show, params: { id: 1 }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
        expect(response.status).to eq(401)
      end

      it 'returns http success for sales' do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: { role: 'sales'}})
        get :show, params: { id: 1 }
        expect(response.status).to eq(200)
      end

      it 'returns http success for disbursement' do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: { role: 'disbursement'}})
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
end
