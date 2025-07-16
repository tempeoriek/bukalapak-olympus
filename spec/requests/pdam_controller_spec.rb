require "rails_helper"

RSpec.describe PdamController, type: :controller do
  include AuthHelper

  let(:operator_id) { 1 }
  let(:customer_number) { '1998800007' }
  let(:pdam_operator) {
    build_stubbed(:pdam_operator)
  }
  let(:pdam_operators) {
    [build_stubbed(:pdam_operator), build_stubbed(:pdam_operator)]
  }
  let(:active_autoswitch_member) {
    build_stubbed(:pdam_autoswitch_group_member, state: 1)
  }
  let(:inactive_autoswitch_member) {
    build_stubbed(:pdam_autoswitch_group_member, state: 0)
  }
  let(:inquiry_response) { build(:sepulsa_response, :pdam_inquiry).with_indifferent_access }
  let(:expected_inquiry_response) {
    JSON.parse({
      customer_number: '1998800007',
      customer_name: 'Putin',
      penalty_fee: 10000,
      amount: 187000,
      address: nil,
      usage: 28,
      admin_charge: (2 * (Test::ADMIN_CHARGE) ),
      start_bill_period: "2017-08-01",
      end_bill_period: "2017-09-01",
      start_usage_meter: 527,
      end_usage_meter: 541,
      stand_meter: nil,
      segel: nil,
      retribution: nil,
      bills_period: "01 Agu 2017 - 01 Sep 2017",
      operator: {
        id: pdam_operator.id,
        name: 'Denpasar',
        group: 'Bali',
        image_url: 'http://i0.kym-cdn.com/entries/icons/mobile/000/013/564/doge.jpg',
        terms_and_conditions: 'term and conditions'
      },
      bills: [
        {
          bill_period: Converter::StringToDate.convert("201708", string_format: "yyyymm"),
          amount: 100000,
          penalty_fee: 10000,
          cubication: '527-541',
          usage: 14
        },
        {
          bill_period: Converter::StringToDate.convert("201709", string_format: "yyyymm"),
          amount: 74000,
          penalty_fee: 0,
          cubication: '527-541',
          usage: 14
        }
      ],
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
    allow(::Toggle::PdamAutoswitch)
      .to receive(:active?)
      .and_return(true)
  end


  describe 'GET #operators' do
    before do
      allow(PdamAutoswitchGroupMember).to receive_message_chain(:where, :pluck).and_return([])
      allow(PdamOperator).to receive(:where).with("id IN (?) AND code NOT IN (?) AND active = TRUE", [], Array(WhitelistPdamOperatorCodes)).and_return(pdam_operators)
      get :operators
    end

    it 'returns http success' do
      expect(response).to have_http_status(:success)
      expect(response.status).to eq(200)
    end

    context 'when there are active and inactive autoswitch members' do
      before do
        allow(PdamAutoswitchGroupMember).to receive_message_chain(:where, :pluck).and_return([1, 2])
        allow(PdamOperator).to receive(:where).with("id IN (?) AND code NOT IN (?) AND active = TRUE", [1, 2], Array(WhitelistPdamOperatorCodes)).and_return(pdam_operators)
        get :operators
      end

      it 'returns http success and active member operators' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)["data"].length).to eq(2)
      end
    end
  end

  describe 'O2OVPD-1293, O2OVPD-1589:: POST #inquiries' do

    context 'when inquiry success' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)
      end

      context 'with sepulsa as partner' do
        before do
          allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
          post :inquiries, params: { customer_number: customer_number, operator_id: operator_id }
        end

        it 'returns http success' do
          expect(response).to have_http_status(:success)
          expect(response.status).to eq(200)
        end

        it 'returns correct json' do
          hash_body = nil
          expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
          expect(hash_body[:data]).to match(expected_inquiry_response)
          expect(hash_body[:data]).not_to have_key(:sub_segment)
          expect(hash_body[:data]).not_to have_key(:biller_ref)
        end
      end

      context 'with mkm_thor as partner' do
        let(:pdam_operator) { build_stubbed(:pdam_operator, :mkm_thor) }
        let(:inquiry_response) { build(:mkm_thor_response, :pdam_inquiry).with_indifferent_access }

        before do
          allow_any_instance_of(Channel::Thor::Base).to receive(:inquiry).and_return(inquiry_response)
          post :inquiries, params: { customer_number: customer_number, operator_id: operator_id }
        end

        it 'returns correct json' do
          hash_body = nil
          expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
          expect(hash_body[:data]).to have_key(:sub_segment)
          expect(hash_body[:data]).to have_key(:biller_ref)
        end
      end

      context 'with fortuna_thor as partner' do
        let(:pdam_operator) { build_stubbed(:pdam_operator, :fortuna_thor) }
        let(:inquiry_response) { build(:fortuna_thor_response, :pdam_inquiry).with_indifferent_access }

        before do
          allow_any_instance_of(Channel::Thor::Base).to receive(:inquiry).and_return(inquiry_response)
          post :inquiries, params: { customer_number: customer_number, operator_id: operator_id }
        end

        it 'returns correct json' do
          hash_body = nil
          expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
          expect(hash_body[:data]).to have_key(:sub_segment)
          expect(hash_body[:data]).to have_key(:biller_ref)
          expect(hash_body[:data]).to have_key(:usage_unit)
        end
      end
    end

    context 'when inquiry error' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)
      end

      it 'returns http error and correct json UnregisteredNumber' do
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_raise(Exceptions::UnregisteredNumber)
        post :inquiries, params: { customer_number: customer_number, operator_id: operator_id }

        expect(response).to have_http_status(422)
        expect(response.status).to eq(422)

        hash_body = nil
        hash_body = JSON.parse(response.body)
        expect(hash_body['errors']).to match([
          {
            'code' => 18117,
            'message' => 'Nomor tidak terdaftar. Coba periksa lagi, yuk.'
          }
        ])
      end

      it 'returns http error and correct json BillAlreadyPaid' do
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_raise(Exceptions::BillAlreadyPaid)
        post :inquiries, params: { customer_number: customer_number, operator_id: operator_id }

        expect(response).to have_http_status(422)
        expect(response.status).to eq(422)

        hash_body = nil
        hash_body = JSON.parse(response.body)
        expect(hash_body['errors']).to match([
          {
            'code' => 18118,
            'message' => 'Tagihan tidak ditemukan atau sudah dibayar.'
          }
        ])
      end

      it 'returns http error and correct json default error' do
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_raise(Exceptions::TransactionCannotBeDone)
        post :inquiries, params: { customer_number: customer_number, operator_id: operator_id }

        expect(response).to have_http_status(422)
        expect(response.status).to eq(422)

        hash_body = nil
        hash_body = JSON.parse(response.body)
        expect(hash_body['errors']).to match([
          {
            'code' => 18119,
            'message' => 'Terjadi kesalahan pada sistem. Silahkan coba lagi.'
          }
        ])
      end
    end
  end

  describe 'POST #create' do
    let(:transaction){ build_stubbed(:pdam_transaction_with_bill) }
    let(:expected_create_response) {
      JSON.parse({
        id: transaction.id,
        customer_number: "1998800007",
        customer_name: "Putin",
        start_bill_period: "2012-01-01",
        end_bill_period: "2012-01-15",
        operator: {
          id: transaction.pdam_operator.id ,
          name: "Denpasar",
          group: "Bali",
          image_url: "http://i0.kym-cdn.com/entries/icons/mobile/000/013/564/doge.jpg",
          terms_and_conditions: "term and conditions",
          have_issue: "false",
          update_selling_price: false
        },
        state_changed_at: {
          processed_at: nil,
          succeeded_at: nil,
          failed_at: nil
        },
        amount: 12610,
        penalty_fee: 0,
        state: "pending",
        invoice_id: 1,
        admin_charge: (2 * (Test::ADMIN_CHARGE) ),
        usage: 2,
        remote_transaction_id: 33,
        address: nil,
        start_usage_meter: 1,
        end_usage_meter: 4,
        reference_number: nil,
        stand_meter: nil,
        segel: 0,
        retribution: 0,
        bills: [
          {
            bill_period: Date.current.beginning_of_month - 1.month,
            penalty_fee: 0,
            amount: 11100,
            cubication: "00000001-00000002",
            tariff: nil,
            usage: 1
          },
          {
            bill_period: Date.current.beginning_of_month,
            penalty_fee: 0,
            amount: 11100,
            cubication: "00000003-00000004",
            tariff: nil,
            usage: 1
          }
        ],
        buyer_id: 1,
        type: 'pdam',
        partner: {
          name: 'PT Sepulsa Teknologi Indonesia'
        },
        transaction_type: 'normal',
        bills_period: '1 - 15 Jan 2012'
      }.to_json).with_indifferent_access
    }

    before do
      allow_any_instance_of(Action::PdamTransaction::Create).to receive(:run!).and_return(transaction)
      allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)
      allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
      post :create, params: { customer_number: customer_number, operator_id: operator_id }
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
      let(:transaction) { build_stubbed(:pdam_transaction_with_bill) }

      before do
        allow(PdamTransaction).to receive(:find_by_id).and_return(transaction)
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
      allow(PdamTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'transaction not present' do

      let(:transaction) { build_stubbed(:pdam_transaction_with_bill) }

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
      let(:transaction) { build_stubbed(:pdam_transaction_with_bill) }
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
      allow(PdamTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'transaction not present' do

      let(:transaction) { build_stubbed(:pdam_transaction_with_bill) }

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
      let(:transaction) { build(:pdam_transaction_with_bill) }

      it 'returns http success' do
        post :invoicing, params: { id: 1,  invoice_id: 1 }
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'O2OVPE-927: POST #confirm' do

    before do
      allow_any_instance_of(Authenticate).to receive(:http_basic_authenticate).and_return true
      allow(PdamTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'transaction not present' do

      let(:transaction) { build_stubbed(:pdam_transaction_with_bill) }

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
      let(:transaction) { build(:pdam_transaction_with_bill) }

      it 'returns http success' do
        post :confirm, params: { id: 1 }
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'O2OVPE-69: GET #has_transacted' do
    before do
      allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
    end

    context 'when user has not transacted' do
      it 'returns false' do
        get :has_transacted
        expect(JSON.parse(response.body).with_indifferent_access[:data][:has_transacted]).to eq(false)
        expect(response.status).to eq(200)
      end
    end

    context 'when user has transacted' do
      let(:transaction) { build_stubbed(:pdam_transaction_with_bill) }

      before do
        allow(PdamTransaction).to receive(:find_by).and_return(transaction)
      end

      it 'returns true' do
        get :has_transacted
        expect(JSON.parse(response.body).with_indifferent_access[:data][:has_transacted]).to eq(true)
        expect(response.status).to eq(200)
      end
    end

    context 'when non login user' do
      before do
        decoded_token[:resource_owner_id] = 0
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
      end

      it 'returns http unauthorized' do
        get :has_transacted

        expect(response.status).to eq(401)
      end
    end
  end
end
