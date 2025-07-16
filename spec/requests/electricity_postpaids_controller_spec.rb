require "rails_helper"

RSpec.describe ElectricityPostpaidsController, type: :controller do
  include AuthHelper
  include Authenticate

  let(:customer_number) { '512345600003' }
  let(:partner_sepulsa) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }
  let(:partner_bukopin) { build_stubbed(:electricity_postpaid_partner, :bukopin) }
  let(:register_transaction_response) { { id: 1 } }
  let(:partner) { { } }
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

  ## Data for partner Sepulsa
  let(:sepulsa_inquiry_response) {
    {
      subscriber_id: '512345600003',
      subscriber_name: 'SERTU SABARIYANTO',
      subscriber_segmentation: 'R1',
      power: '900',
      stand_meter_summary: '00017822 - 00017915',
      bill_status: 2,
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

  let(:expected_sepulsa_inquiry_response) {
    JSON.parse({
      customer_number: "512345600003",
      customer_name: "SERTU SABARIYANTO",
      segmentation: "R1",
      power: 900,
      outstanding_bill: 2,
      unpaid_bill: 0,
      admin_charge: 3000,
      penalty_fee: 3500 + 7500,
      reference_number: nil,
      stand_meter: '00017822 - 00017915',
      period: [
        "2011-03-01",
        "2011-04-01"
      ],
      # total amount is calculated bills amount plus admin charge plus penalty fee
      amount: 40500 + 3000 + 11000,
      bills: [
        {
          bill_period: "2011-03-01",
          penalty_fee: 3500,
          amount: 20500
        },
        {
          bill_period: "2011-04-01",
          penalty_fee: 7500,
          amount: 20000
        }
      ],
      partner: {
        name: 'PT Sepulsa Teknologi Indonesia'
      },
      remaining_billing_sheet: 0
    }.to_json).with_indifferent_access
  }

  let(:expected_sepulsa_create_response) {
    JSON.parse({
      customer_number: "512345600003",
      customer_name: "SERTU SABARIYANTO",
      segmentation: "R1",
      power: 900,
      outstanding_bill: 2,
      unpaid_bill: 0,
      amount: 40500 + 3000 + 11000,
      penalty_fee: 3500 + 7500,
      state: "pending",
      reference_number: nil,
      remote_transaction_id: 1,
      invoice_id: nil,
      processed_at: nil,
      succeeded_at: nil,
      failed_at: nil,
      admin_charge: 3000,
      period: [
        "2011-03-01",
        "2011-04-01"
      ],
      bills: [
        {
          bill_period: "2011-03-01",
          penalty_fee: 3500,
          amount: 20500
        },
        {
          bill_period: "2011-04-01",
          penalty_fee: 7500,
          amount: 20000
        }
      ],
      type: 'electricity_postpaid',
      image_url: "https://s4.bukalapak.com/images/virtual_product/logo_pln.png",
      partner: {
        name: 'PT Sepulsa Teknologi Indonesia'
      }
    }.to_json).with_indifferent_access
  }

  ## Data from partner Bukopin
  let(:bukopin_inquiry_response) {
    {
    :customer_number=>"512345600003",
    :customer_name=>"SUBCRIBER NAME           ",
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

  let(:expected_bukopin_inquiry_response) {
    JSON.parse({
      customer_number: "512345600003",
      customer_name: "SUBCRIBER NAME",
      segmentation: "R1",
      power: 1300,
      outstanding_bill: 1,
      unpaid_bill: 0,
      admin_charge: 2750,
      penalty_fee: 0,
      reference_number: "2FED321E2298361A198B6CB141138DBD",
      stand_meter: '00001111 - 00002222',
      period: [
        "2018-07-01"
      ],
      # total amount is calculated bills amount plus admin charge plus penalty fee
      amount: 300000 + 2750 + 0,
      bills: [
        {
          bill_period: "2018-07-01",
          penalty_fee: 0,
          amount: 300000
        }
      ],
      partner: {
        name: 'PT Bank Bukopin Tbk'
      },
      remaining_billing_sheet: 0
    }.to_json).with_indifferent_access
  }

  let(:expected_bukopin_create_response) {
    JSON.parse({
      customer_number: "512345600003",
      customer_name: "SUBCRIBER NAME",
      segmentation: "R1",
      power: 1300,
      outstanding_bill: 1,
      unpaid_bill: 0,
      amount: 302750,
      penalty_fee: 0,
      state: "pending",
      reference_number: "2FED321E2298361A198B6CB141138DBD",
      remote_transaction_id: 1,
      invoice_id: nil,
      processed_at: nil,
      succeeded_at: nil,
      failed_at: nil,
      admin_charge: 2750,
      period: [
        "2018-07-01",
      ],
      bills: [
        {
          bill_period: "2018-07-01",
          penalty_fee: 0,
          amount: 300000
        }
      ],
      type: 'electricity_postpaid',
      image_url: "https://s4.bukalapak.com/images/virtual_product/logo_pln.png",
      partner: {
        name: 'PT Bank Bukopin Tbk'
      }
    }.to_json).with_indifferent_access
  }

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow(ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner)
    allow(ElectricityPostpaidPartner).to receive(:find_by).with(name: 'bukopin').and_return(partner_bukopin)
    allow(ElectricityPostpaidPartner).to receive(:find_by).with(name: 'unknown').and_return(nil)
    allow_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return(register_transaction_response)
    allow(Time.zone).to receive(:now).and_return(Time.zone.parse("01:01"))
    allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return true
    allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
  end

  describe 'POST #inquiries' do
    context 'partner sepulsa' do
      let(:partner) { partner_sepulsa }

      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false} })
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(sepulsa_inquiry_response)
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        post :inquiries, params: { customer_number: customer_number }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to match(expected_sepulsa_inquiry_response)
      end
    end

    context 'partner bukopin BMI' do
      let(:partner) { partner_bukopin }

      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {o2o_agent: {status: "confirmed"}} })
        expect(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:new).with(customer_number, buyer_type: AGENT_BUYER_TYPE).and_call_original
        allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:run!).and_return(bukopin_inquiry_response)
        post :inquiries, params: { customer_number: customer_number }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to match(expected_bukopin_inquiry_response)
      end
    end

    context 'partner bukopin Normal' do
      let(:partner) { partner_bukopin }

      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false} })
        allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:run!).and_return(bukopin_inquiry_response)
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        post :inquiries, params: { customer_number: customer_number }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to match(expected_bukopin_inquiry_response)
      end
    end

    context 'choose correct partner bukopin' do
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false} })
        allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:run!).and_return(bukopin_inquiry_response)
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        post :inquiries, params: { customer_number: customer_number, partner: "bukopin"}
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to match(expected_bukopin_inquiry_response)
      end
    end

    context 'error unknown partner' do
      it {
        allow(::ElectricityPostpaidPartner).to receive(:find_by).and_return nil
        post :inquiries, params: { customer_number: customer_number }
        expect(response.status).to eq(422)
      }
    end

    context 'when invalid parameter' do
      context 'no customer_number' do
        it {
          post :inquiries, params: {}
          expect(response.status).to eq(422)
        }
      end

      context 'invalid length of customer_number' do
        it {
          post :inquiries, params: { customer_number: '123' }
          expect(response.status).to eq(422)
        }
      end
    end

    context 'when error UnregisteredNumber' do
      let(:partner) { partner_sepulsa }
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false} })
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_raise(Exceptions::UnregisteredNumber)
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        post :inquiries, params: { customer_number: customer_number }
      end

      it {
        expect(response.status).to eq(422)
        hash_body = JSON.parse(response.body)
        expect(hash_body['errors']).to match([
          {
            'code' => 18117,
            'message' => 'Nomor tidak terdaftar. Coba periksa lagi, yuk.'
          }
        ])
      }
    end

    context 'when error BillAlreadyPaid' do
      let(:partner) { partner_sepulsa }
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false} })
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_raise(Exceptions::BillAlreadyPaid)
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        post :inquiries, params: { customer_number: customer_number }
      end

      it {
        expect(response.status).to eq(422)
        hash_body = JSON.parse(response.body)
        expect(hash_body['errors']).to match([
          {
            'code' => 18118,
            'message' => 'Tagihan tidak ditemukan atau sudah dibayar.'
          }
        ])
      }
    end

    context 'when error default' do
      let(:partner) { partner_sepulsa }
      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {agent: false} })
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_raise(Exceptions::TransactionCannotBeDone)
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        post :inquiries, params: { customer_number: customer_number }
      end

      it {
        expect(response.status).to eq(422)
        hash_body = JSON.parse(response.body)
        expect(hash_body['errors']).to match([
          {
            'code' => 18119,
            'message' => 'Terjadi kesalahan pada sistem. Silahkan coba lagi.'
          }
        ])
      }
    end
  end

  describe 'O2OVPE-271: POST #create' do
    context 'partner sepulsa' do
      let(:partner) { partner_sepulsa }

      before do
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(sepulsa_inquiry_response)
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        post :create, params: { customer_number: customer_number }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(201)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to include(expected_sepulsa_create_response)
      end
    end

    context 'partner bukopin BMI' do
      let(:partner) { partner_bukopin }

      before do
        allow(JsonWebToken).to receive(:decode).and_return({ resource_owner_id: 1, resource_owner: {o2o_agent: {status: "confirmed"}} })
        expect(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:new).with(customer_number, buyer_type: AGENT_BUYER_TYPE).and_call_original
        allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:run!).and_return(bukopin_inquiry_response)
        post :create, params: { customer_number: customer_number }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(201)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to include(expected_bukopin_create_response)
      end
    end

    context 'partner bukopin' do
      let(:partner) { partner_bukopin }

      before do
        expect(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:new).with(customer_number, buyer_type: AGENT_BUYER_TYPE).and_call_original
        allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:run!).and_return(bukopin_inquiry_response)
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        post :create, params: { customer_number: customer_number }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(201)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to include(expected_bukopin_create_response)
      end
    end

    context 'choose correct partner bukopin' do
      before do
        allow_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:run!).and_return(bukopin_inquiry_response)
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        post :create, params: { customer_number: customer_number, partner: "bukopin"}
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(201)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to include(expected_bukopin_create_response)
      end
    end

    context 'error unknown partner' do
      it {
        allow(::ElectricityPostpaidPartner).to receive(:find_by).and_return nil
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        post :inquiries, params: { customer_number: customer_number }
        expect(response.status).to eq(422)
      }
    end

    context 'mass bill transaction' do
      let(:partner) { partner_sepulsa }

      before do
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(sepulsa_inquiry_response)
        allow(JsonWebToken).to receive(:decode).and_return(decoded_token)
        post :create, params: { customer_number: customer_number, mass_bill_id: "a987fbc9-4bed-3078-cf07-9141ba07c9f3" }
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(201)
      end

      it 'returns correct json' do
        hash_body = nil
        expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
        expect(hash_body[:data]).to include(expected_sepulsa_create_response) # TODO: update to mass bill response
      end
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
      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill) }

      before do
        allow(PostpaidTransaction).to receive(:find_by_id).and_return(transaction)
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
      allow(PostpaidTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'transaction not present' do

      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill) }

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
      end

      let(:mock_postpaid) { instance_double(Action::PostpaidTransaction::Process) }
      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill) }
      let(:payment_id) { "BL190102ABCDEINV" }

      it 'returns http success' do
        allow(mock_postpaid).to receive(:run!)
        post :pay, params: { id: 1, payment_id: payment_id }
        expect(response.status).to eq(200)
      end

      it 'return ok' do
        allow(mock_postpaid).to receive(:run!).and_raise(Exceptions::CannotProcessTransaction)
        post :pay, params: { id: 1, payment_id: payment_id }
        expect(response.status).to eq(200)
      end
    end

  end

  describe 'POST #invoicing' do

    before do
      allow_any_instance_of(Authenticate).to receive(:http_basic_authenticate).and_return true
      allow(PostpaidTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'transaction not present' do

      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill) }

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
      let(:transaction) { build(:postpaid_transaction_with_bill) }

      it 'returns http success' do
        post :invoicing, params: { id: 1,  invoice_id: 1 }
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'POST #confirm' do
    before do
      allow_any_instance_of(Authenticate).to receive(:http_basic_authenticate).and_return true
      allow(PostpaidTransaction).to receive(:find_by).and_return(transaction)
    end

    context 'transaction not present' do

      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill) }

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
      let(:transaction) { build(:postpaid_transaction_with_bill) }

      it 'returns http success' do
        post :confirm, params: { id: 1 }
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'GET #get_receipt' do
    before do
      expect(JsonWebToken).to receive(:decode).and_return(decoded_token)
      expect(PostpaidTransaction).to receive(:find_by_id).and_return(transaction)
    end

    context 'unauthorized user' do
      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill, buyer_id: 2) }

      it 'returns transaction not found' do
        get :get_receipt, params: { id: 1, type: 'png' }
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18107)
        expect(response.status).to eq(401)
      end
    end

    context 'when response is ok' do
      let(:transaction) { create(:postpaid_transaction_with_bill, :partner_succeeded, buyer_id: 1) }
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

  describe 'O2OVPD-1697: GET #has_transacted' do
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
      let(:transaction) { build_stubbed(:postpaid_transaction_with_bill) }

      before do
        allow(PostpaidTransaction).to receive(:find_by).and_return(transaction)
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
