require "rails_helper"
require 'support/sepulsa/pdam_response'

RSpec.describe Internal::PdamController, type: :controller do
  include_context 'pdam_response'
  include AuthHelper
  RSpec::Matchers.define_negated_matcher :not_raise_error, :raise_error

  let(:operator_id) { 1 }
  let(:autoswitch_group_id) { 1 }
  let(:customer_number) { '1998800007' }
  let(:pdam_operator) {
    build_stubbed(:pdam_operator)
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
      bills_period: '01 Agu 2017 - 01 Sep 2017',
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
  let(:time_now) { Time.now }

  before do
    allow(Time).to receive(:now).and_return(time_now)
    allow(::Toggle::PdamAutoswitch)
      .to receive(:active?)
      .and_return(true)
  end

  before { http_login_new }

  describe 'POST #inquiries' do
    context 'when operator found' do
      before do
        allow_any_instance_of(described_class).to receive(:select_active_operator_by_group_id).and_return pdam_operator
        allow_any_instance_of(Channel::Sepulsa::Base).to receive(:inquiry).and_return(inquiry_response)
        allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)

        post :inquiries, params: { customer_number: customer_number, autoswitch_group_id: autoswitch_group_id }
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

    context 'when operator not found' do
      before do
        allow_any_instance_of(described_class).to receive(:select_active_operator_by_group_id).and_return nil

        post :inquiries, params: { customer_number: customer_number, autoswitch_group_id: autoswitch_group_id }
      end

      it 'returns http errror' do
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.status).to eq(422)
        expect(JSON.parse(response.body)['errors'][0]['message']).to eq 'Operator ID Not Found'
      end
    end

    context 'when customer number not valid' do
      before do
        allow_any_instance_of(described_class).to receive(:select_active_operator_by_group_id).and_return pdam_operator
        allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)

      end

      context 'when customer number nil' do
        before do
          post :inquiries, params: { customer_number: nil, autoswitch_group_id: autoswitch_group_id }
        end

        it 'returns http errror' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.status).to eq(422)
          expect(JSON.parse(response.body)['errors'][0]['message']).to eq 'Info yang kamu masukkan salah :( mohon diteliti kembali'
        end
      end

      context 'when customer number is empty string' do
        before do
          post :inquiries, params: { customer_number: '', autoswitch_group_id: autoswitch_group_id }
        end

        it 'returns http errror' do
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response.status).to eq(422)
          expect(JSON.parse(response.body)['errors'][0]['message']).to eq 'Info yang kamu masukkan salah :( mohon diteliti kembali'
        end
      end
    end
  end

  describe 'GET #show' do
    let(:transaction) { create(:pdam_transaction_with_bill) }
    let(:params) { { id: 1 } }
    let(:expected_labels) do
      {
        status: response_request_status,
        route: 'test.host/_internal/pdam/transactions/id',
        method: 'GET',
        transaction_type: 'internal',
        product: 'pdam',
        http_code: http_response_code,
        created_on: nil
      }
    end

    before { http_login_new }

    context 'when transaction found' do
      let(:http_response_code) { HTTP_STATUS_OK }
      let(:response_request_status) { 'ok' }

      before { allow(::PdamTransaction).to receive(:find_by_id).and_return transaction }

      it 'returns HTTP status OK' do
        # Observer.histogram(Observer::Metric::API, latency_duration, metric_labels)
        expect(Observer).to receive(:histogram).with(Observer::Metric::API, 0.0, expected_labels).and_return(true)
        get :show, params: params
        expect(response).to have_http_status(http_response_code)
      end
    end

    context 'when transaction not found' do
      let(:http_response_code) { HTTP_STATUS_NOT_FOUND }
      let(:response_request_status) { 'fail' }

      before { allow(::PdamTransaction).to receive(:find_by_id).and_return nil }

      it 'returns HTTP status not found' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::API, 0.0, expected_labels).and_return(true)
        get :show, params: params
        expect(response).to have_http_status(HTTP_STATUS_NOT_FOUND)
      end
    end
  end

  describe 'PATCH #status' do
    before { http_login_new }

    context 'when failing a pending transaction' do
      let(:params) {{ id: 1, status: 'failed' }}
      let(:transaction) { build(:pdam_transaction_with_bill) }
      it 'expire the transaction' do
        expect(PdamTransaction).to receive(:find_by_id).and_return(transaction)

        expect { post :status, params: params }.not_to raise_error
        expect(transaction.state).to eq('expired')
      end
    end

    context 'when failing a paid transaction' do
      let(:params) {{ id: 1, status: 'failed' }}
      let(:transaction) { build(:pdam_transaction_with_bill, :paid) }
      it 'fail the transaction' do
        expect(PdamTransaction).to receive(:find_by_id).and_return(transaction)

        expect { post :status, params: params }.not_to raise_error
        expect(transaction.state).to eq('failed')
      end
    end

    context 'when failing a processed transaction' do
      let(:params) {{ id: 1, status: 'failed' }}
      let(:transaction) { build(:pdam_transaction_with_bill, :processed) }
      it 'fail the transaction' do
        expect(PdamTransaction).to receive(:find_by_id).and_return(transaction)

        expect { post :status, params: params }.not_to raise_error
        expect(transaction.state).to eq('failed')
      end
    end

    context 'when failing a partner_failed transaction' do
      let(:params) {{ id: 1, status: 'failed' }}
      let(:transaction) { build(:pdam_transaction_with_bill, :partner_failed) }
      it 'fail the transaction' do
        expect(PdamTransaction).to receive(:find_by_id).and_return(transaction)

        expect { post :status, params: params }.not_to raise_error
        expect(transaction.state).to eq('failed')
      end
    end

    context 'when success a paid transaction' do
      let(:params) {{ id: 1, status: 'succeed' }}
      let(:transaction) { build(:pdam_transaction_with_bill, :paid) }
      it 'success the transaction' do
        expect(PdamTransaction).to receive(:find_by_id).and_return(transaction)

        expect { post :status, params: params }.not_to raise_error
        expect(transaction.state).to eq('succeeded')
      end
    end

    context 'when success a processed transaction' do
      let(:params) {{ id: 1, status: 'succeed' }}
      let(:transaction) { build(:pdam_transaction_with_bill, :processed) }
      it 'success the transaction' do
        expect(PdamTransaction).to receive(:find_by_id).and_return(transaction)

        expect { post :status, params: params }.not_to raise_error
        expect(transaction.state).to eq('succeeded')
      end
    end

    context 'when success a partner_succeeded transaction' do
      let(:params) {{ id: 1, status: 'succeed' }}
      let(:transaction) { build(:pdam_transaction_with_bill, :partner_succeeded) }
      it 'success the transaction' do
        expect(PdamTransaction).to receive(:find_by_id).and_return(transaction)

        expect { post :status, params: params }.not_to raise_error
        expect(transaction.state).to eq('succeeded')
      end
    end

    context 'when expire a pending transaction' do
      let(:params) {{ id: 1, status: 'expired' }}
      let(:transaction) { build(:pdam_transaction_with_bill) }
      it 'expire the transaction' do
        expect(PdamTransaction).to receive(:find_by_id).and_return(transaction)

        expect { post :status, params: params }.not_to raise_error
        expect(transaction.state).to eq('expired')
      end
    end

    context 'with unknown status' do
      let(:params) {{ id: 1, status: 'married' }}
      let(:transaction) { build(:pdam_transaction_with_bill) }
      it 'expire the transaction' do
        expect(PdamTransaction).to receive(:find_by_id).and_return(transaction)

        expect { post :status, params: params }.not_to raise_error
        expect(transaction.state).to eq('pending')
      end
    end
  end

  describe 'POST #create' do
    subject { post :create, params: { customer_number: customer_number, autoswitch_group_id: autoswitch_group_id, buyer_id: 1 } }

    before do
      allow_any_instance_of(described_class).to receive(:select_active_operator_by_group_id).and_return pdam_operator
      allow(PdamOperator).to receive(:find_by_id).and_return(pdam_operator)
      allow_any_instance_of(PdamTransaction).to receive(:pdam_operator).and_return(pdam_operator)
    end

    context 'negative flow' do
      context 'failed authentication' do
        before do
          request.env['HTTP_AUTHORIZATION'] = nil
        end

        it 'does not raising any errors' do
          expect { subject }.not_to raise_error
        end

        it 'returns expected response' do
          subject
          expect(response.status).to eq(401)
        end
      end

      context 'Autoswitch Group not found' do
        before do
          expect_any_instance_of(described_class).to receive(:select_active_operator_by_group_id).and_raise(::Exceptions::AutoswitchGroupNotFound)
        end

        it 'does not raising any errors' do
          expect { subject }.not_to raise_error
        end

        it 'returns expected response' do
          subject
          expect(response.status).to eq(404)
        end
      end

      context 'Invalid Operator ID' do
        before do
          expect(PdamOperator).to receive(:find_by_id).and_return(nil)
        end
        it 'does not raising any errors' do
          expect { subject }.not_to raise_error
        end

        it 'returns expected response' do
          subject
          expect(response.status).to eq(422)
        end
      end
    end

    context 'happy flow' do
      before do
        stub_request(:post, /inquire.json/).to_return(status: 200, body: sepulsa_pdam_single_bill_inquiry_success_response.to_json, headers: {})
        stub_request(:post, /transaction.json/).to_return(status: 200, body: sepulsa_pdam_single_bill_create_success_response.to_json, headers: {})
        stub_request(:post, /_internal\/remote\/transactions/).to_return(status: 201, body: {data: {id: 1, state: 'pending'}}.to_json, headers: {})
      end
      let(:response_body) { JSON.parse(response.body).with_indifferent_access[:data] }

      it 'does not raising any errors and creates new transaction' do
        expect { subject }.to change { PdamTransaction.count }.by(1)
          .and not_raise_error
      end

      it 'returns expected response' do
        expect(Form::Pdam).to receive(:new).with(anything, anything, anything, NORMAL_BUYER_TYPE).and_call_original
        subject
        expect(response.status).to eq(201)
        expect(response_body[:state]).to eq('pending')
      end

      context 'request from middleman service' do
        before do
          request.env['HTTP_BL_SERVICE'] = 'middleman'
        end

        it 'does not raising any errors and creates new transaction' do
          expect { subject }.to change { PdamTransaction.count }.by(1)
            .and not_raise_error
        end

        it 'returns expected response' do
          expect(Form::Pdam).to receive(:new).with(anything, anything, anything, COLLECTING_AGENT_BUYER_TYPE).and_call_original
          subject
          expect(response.status).to eq(201)
          expect(response_body[:state]).to eq('pending')
        end
      end
    end
  end

  describe 'POST #commission' do
    let(:amount) { 1000 }
    let(:transaction) { create(:pdam_transaction_with_bill, amount: amount) }
    let(:commission_setting) { build_stubbed(:pdam_operator_commission_setting) }
    let(:commission_settings) { create_list(:pdam_operator_commission_setting, 1, pdam_operator: transaction.pdam_operator) }
    let(:commission) do
      {
        data: {
          value: 10,
          min_transaction_value: 1_000,
          max_transaction_value: 1_000_000,
        },
        meta: {
          http_status: 200
        }
      }
    end
    let(:zero_commission) do
      {
        data: {
          value: 0,
          min_transaction_value: 0,
          max_transaction_value: 100_000_000,
        },
        meta: {
          http_status: 200
        }
      }
    end

    before do
      allow(controller).to receive(:http_basic_authenticate).and_return(true)
    end

    context 'transaction found' do
      before do
        transaction
        commission_settings
        allow(Action::PdamTransaction::CalculateCommission).to receive_message_chain(:new, :run!).and_return(commission_setting)
      end

      it 'calculates and returns commission' do
        post :commission, params: { id: transaction.id }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to eq(commission.as_json)
      end
    end

    context 'transaction not found' do
      before do
        allow(PdamTransaction).to receive(:find_by_id).and_return(nil)
      end

      it 'returns transaction not found error' do
        post :commission, params: { id: -1 }
        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)["errors"][0]["code"]).to eq(18108)
      end
    end

    context 'O2OVPE-1070: commission not found' do
      before do
        transaction
      end

      it 'returns zero commission' do
        post :commission, params: { id: transaction.id }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to eq(zero_commission.as_json)
      end
    end

    context 'transaction amount not in range found' do
      let(:amount) { 999 }

      before do
        transaction
        commission_setting
      end

      it 'returns zero commission' do
        post :commission, params: { id: transaction.id }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)).to eq(zero_commission.as_json)
      end
    end
  end
end
