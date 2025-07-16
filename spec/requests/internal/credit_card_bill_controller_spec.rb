require "rails_helper"
include AuthHelper

RSpec.describe Internal::CreditCardBillController, type: :controller do

  let(:transaction) {
    build(:cc_transaction, :visa)
  }

  let(:transaction_processed) {
    build(:cc_transaction, :processed_visa)
  }

  let(:transaction_processed_with_partner_trx_id) {
    build(:cc_transaction, :processed_visa, :visa, :partner_transaction_id => 123)
  }

  let(:transaction_succeeded) {
    build(:cc_transaction, :succeeded, :visa)
  }

  let(:remote_id) { { id: 1 } }
  let(:customer_number) { '4665730000000117' }
  let(:credit_card_biller) { transaction_bni.credit_card_biller }
  let(:biller_id) { credit_card_biller.id }
  let(:transaction_bni){ build(:cc_transaction) }
  let(:pay_amount) { 500000 }
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

  before {
    allow_any_instance_of(Authenticate).to receive(:http_basic_authenticate).and_return true
    allow_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).and_return true
    allow_any_instance_of(Sievex::Send).to receive(:run!).and_return true
    allow(GcpsPublisher).to receive(:publish).and_return true
    allow(RedisOlympus).to receive(:set).and_return true
    allow(RedisOlympus).to receive(:get).and_return 1
    allow(Toggles::OlympusSievexPredict).to receive(:active?).and_return false
    allow(::Toggle::CreditCardBill::WhitelistNewBNI).to receive(:active?).and_return(false)
    allow(Toggle::CreditCardBill::NewBNI).to receive(:active?).and_return false
    allow_any_instance_of(::CreditCardBillTransaction).to receive(:reload).and_return true
  }

  describe 'GET #show' do
    let(:response) { get :show, params: { id: 1 } }

    context 'when trx found' do
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by).and_return transaction
        expect(response.status).to eq 200
      }
    end

    context 'when trx not found' do
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by).and_return nil
        expect(response.status).to eq 404
      }
    end
  end

  describe 'POST #create' do
    let(:params) {
      {
        customer_number: customer_number,
        biller_id: "13123",
        amount: "500000",
        buyer_id: "123"
      }
    }
    before do
      allow(Toggles::CreditCardBill).to receive(:active?).and_return true
      allow(Toggles::WhitelistBni).to receive(:active?).and_return false
      allow(Toggles::WhitelistVisa).to receive(:active?).and_return false
      allow_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return(remote_id)
      allow(CreditCardBiller).to receive(:find).and_return(credit_card_biller)
      allow_any_instance_of(CreditCardBillTransaction).to receive(:biller).and_return(transaction_bni.biller)
      allow_any_instance_of(CreditCardBillTransaction).to receive(:partner).and_return(transaction_bni.partner)
      allow(Channel::Connection::Http).to receive(:post).and_return(bni_inquiry_response)
    end

    context 'when BL_Service not middleman' do
      let(:header) {
        {
          'HTTP_BL_SERVICE' => 'gachaman'
        }
      }
      let(:buyer_type) { "normal" }
      let(:expected_create_response) {
        {
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
          transaction_type: "user",
          partner: {
            name: "PT BNI Tbk"
          }
        }.with_indifferent_access
      }

      before do
        expect(Form::CreditCardBill).to receive(:new)
          .with(customer_number, params[:biller_id], params[:amount], buyer_type).and_call_original
      end

      it 'returns correct json and http status' do
        request.headers.merge!(header)
        post :create, params: params

        hash_body = JSON.parse(response.body).with_indifferent_access
        data = hash_body[:data].merge({
          "id" => transaction.id,
          "invoice_id" => transaction.invoice_id,
        })
        expect(data).to include(expected_create_response)
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(201)
      end
    end

    context 'when bl service is middleman' do
      let(:transaction_bni) { build(:cc_transaction, :partner_pnl) }
      let(:header) {
        {
          'HTTP_BL_SERVICE' => 'middleman'
        }
      }
      let(:pnl_inquiry_response) {{
        "message" => "Akun bank valid.",
        "data" => {"valid" => true, "name" => "JAMIL HAZAMI ULALALA"},
        "meta" => {"http_status" => 200}
      }}
      let(:expected_create_response) {
        {
          invoice_id: transaction.invoice_id,
          remote_transaction_id: 1,
          state: "pending",
          customer_number: customer_number,
          customer_name: "JAMXXXXXXXXXXXXXXALA",
          amount: 505000,
          minimum_payment: nil,
          statement_date: expected_dbs_inquiry_response["statement_date"],
          due_date: expected_dbs_inquiry_response["due_date"],
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
          transaction_type: "collecting_agent",
          partner: {
            name: "PT Bank DBS Indonesia"
          }
        }.with_indifferent_access
      }
      let(:buyer_type) { COLLECTING_AGENT_BUYER_TYPE }

      context 'when partner is not pnl' do
        let(:transaction_bni) { build(:cc_transaction, :visa) }

        before do
          expect(Form::CreditCardBill).to receive(:new)
          .with(customer_number, params[:biller_id], params[:amount], buyer_type).and_call_original
        end

        it 'raise correct http status' do
          request.headers.merge!(header)
          post :create, params: params
          expect(response.status).to eq(422)
        end
      end

      context 'when valid partner' do
        before do
          allow(Channel::Connection::Http).to receive(:post).and_return(pnl_inquiry_response.to_json)
          expect(Form::CreditCardBill).to receive(:new)
          .with(customer_number, params[:biller_id], params[:amount], buyer_type).and_call_original
        end

        it 'returns correct json and http status' do
          request.headers.merge!(header)
          post :create, params: params

          hash_body = JSON.parse(response.body).with_indifferent_access
          data = hash_body[:data].merge({
            "id" => transaction.id,
            "invoice_id" => transaction.invoice_id,
            })
          expect(data).to include(expected_create_response)
          expect(response).to have_http_status(:success)
          expect(response.status).to eq(201)
        end
      end
    end
  end

  describe 'POST #pay' do
    let(:response) { post :pay, params: { id: 1 } }

    context 'when trx found' do
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by).and_return transaction
        expect(response.status).to eq 200
      }
    end

    context 'when trx not found' do
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by).and_return nil
        expect(response.status).to eq 404
      }
    end

    context 'when trx wrong state or already processed with partner_transaction_id' do
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by).and_return transaction_succeeded
        expect(response.status).to eq 200
      }
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by).and_return transaction_processed_with_partner_trx_id
        expect(response.status).to eq 200
      }
    end
  end

  describe 'POST #invoicing' do
    let(:response) { post :invoicing, params: { id: 1 } }

    context 'when trx found' do
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by).and_return transaction
        expect(response.status).to eq 200
      }
    end

    context 'when trx not found' do
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by).and_return nil
        expect(response.status).to eq 404
      }
    end

    context 'when trx invalid' do
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by).and_return transaction
        allow_any_instance_of(Action::PostpaidTransaction::Invoicing).to receive(:run!).and_raise Exceptions::CreateTransactionError
        expect(response.status).to eq 422
      }
    end
  end

  describe 'POST #confirm' do
    let(:response) { post :confirm, params: { id: 1 } }

    context 'when trx found' do
      before {
        allow(::CreditCardBillTransaction).to receive(:find_by).and_return transaction
      }
      [:succeeded, :failed, :partner_succeeded, :partner_failed].each do |state|
        context "when trx state is #{state}" do
          let(:transaction) { build(:cc_transaction, state) }
          it {
            expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!)
            expect_any_instance_of(Action::PostpaidTransaction::Confirm).not_to receive(:run!)
            expect(response.status).to eq 200
          }
        end
      end

      context 'when trx state is processed' do
        let(:transaction) { transaction_processed }
        it {
          expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).not_to receive(:run!)
          expect_any_instance_of(Action::PostpaidTransaction::Confirm).to receive(:run!)
          expect(response.status).to eq 200
        }
      end

      [:pending, :paid, :expired, :cancelled].each do |state|
        context "when trx state is #{state}" do
          let(:transaction) { build(:cc_transaction, state) }
          it {
            expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).not_to receive(:run!)
            expect_any_instance_of(Action::PostpaidTransaction::Confirm).not_to receive(:run!)
            expect(response.status).to eq 422
          }
        end
      end
    end

    context 'when trx not found' do
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by).and_return nil
        expect(response.status).to eq 404
      }
    end

  end

  describe 'PATCH #status' do

    before {
      allow(::CreditCardBillTransaction).to receive(:find_by_id).and_return transaction
    }

    context 'when trx state already final' do
      [:succeeded, :failed].each do |state|
        context "when trx state is #{state}" do
          let(:transaction) { build(:cc_transaction, state) }
          let(:response) { patch :status, params: { id: 1, status: 'succeed' } }
          it { expect(response.status).to eq 200 }
        end
      end
    end

    context 'when trx state not final' do
      states_actions = {
        :pending => {
          'failed' =>  { action: :expire!,        http_status: 200 },
          'succeed' => { action: :force_success!, http_status: 200 },
          'expired' => { action: :expire!,        http_status: 200 }
        },
        :processed => {
          'failed' =>  { action: :force_fail!,    http_status: 200 },
          'succeed' => { action: :force_success!, http_status: 200 },
          'expired' => { action: :expire!,        http_status: 200 }
        },
        # :succeeded => {
        #   'failed' =>  { action: :force_fail!,    http_status: 200 },
        #   'succeed' => { action: :force_success!, http_status: 200 },
        #   'expired' => { action: :expire!,        http_status: 200 }
        # },
        # :failed => {
        #   'failed' =>  { action: :force_fail!,    http_status: 200 },
        #   'succeed' => { action: :force_success!, http_status: 200 },
        #   'expired' => { action: :expire!,        http_status: 200 }
        # },
        :paid => {
          'failed' =>  { action: :force_fail!,    http_status: 200 },
          'succeed' => { action: :force_success!, http_status: 200 },
          'expired' => { action: :expire!,        http_status: 200 }
        },
        :partner_succeeded => {
          'failed' =>  { action: :force_fail!,    http_status: 200 },
          'succeed' => { action: :force_success!, http_status: 200 },
          'expired' => { action: :expire!,        http_status: 200 }
        },
        :partner_failed => {
          'failed' =>  { action: :force_fail!,    http_status: 200 },
          'succeed' => { action: :force_success!, http_status: 200 },
          'expired' => { action: :expire!,        http_status: 200 }
        },
        # :expired => {
        #   'failed' =>  { action: :force_fail!,    http_status: 200 },
        #   'succeed' => { action: :force_success!, http_status: 200 },
        #   'expired' => { action: :expire!,        http_status: 200 }
        # },
        :cancelled => {
          'failed' =>  { action: :force_fail!,    http_status: 200 },
          'succeed' => { action: :force_success!, http_status: 200 },
          'expired' => { action: :expire!,        http_status: 200 }
        },
      }

      states_actions.each do |trx_state, to_state_actions|
        context "when trx state is #{trx_state}" do
          to_state_actions.each do |to_state, state_action|
            context "when params[:status] is '#{to_state}'" do
              let(:transaction) { build(:cc_transaction, trx_state) }
              let(:response) { patch :status, params: { id: 1, status: to_state } }
              it {
                expect_any_instance_of(::CreditCardBillTransaction).to receive(state_action[:action])
                if to_state != 'expired'
                  expect_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!)
                end
                expect(response.status).to eq state_action[:http_status]
              }
            end
          end
        end
      end

      context 'when params[:status] is invalid' do
        let(:transaction) { transaction_processed }
        let(:response) { patch :status, params: { id: 1, status: 'invalid' } }
        it {
          expect(response.status).to eq 422
        }
      end
    end

  end

  describe 'POST #pnl_callback' do
    let(:response) { post :pnl_callback, params: { payment_id: 1, status: { status: 'ACTC' }, reference_id: 1 } }

    context 'when trx found' do
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by_remote_transaction_id).and_return transaction_processed_with_partner_trx_id
        expect(response.status).to eq 200
      }
    end

    context 'when trx not found' do
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by_remote_transaction_id).and_return nil
        expect(response.status).to eq 404
      }
    end

    context 'when balance insufficient' do
      let(:response) { post :pnl_callback, params: { payment_id: 1, status: { status: 'RJCT', description: 'Insufficient Funds' }, reference_id: 1 } }
      it {
        allow(::CreditCardBillTransaction).to receive(:find_by_remote_transaction_id).and_return transaction_processed_with_partner_trx_id
        expect(response.status).to eq 200
      }
    end

  end

  describe 'POST #inquiries' do
    before do
      allow(Toggles::CreditCardBill).to receive(:active?).and_return true
      allow(Toggles::WhitelistBni).to receive(:active?).and_return false
      allow(Toggles::WhitelistVisa).to receive(:active?).and_return false
      allow(CreditCardBiller).to receive(:find).and_return(credit_card_biller)
      allow(Channel::Connection::Http).to receive(:post).and_return(bni_inquiry_response)

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
  end

end
