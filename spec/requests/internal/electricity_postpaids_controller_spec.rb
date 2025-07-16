require 'rails_helper'
include AuthHelper

RSpec.describe Internal::ElectricityPostpaidsController, type: :controller do
  before do
    allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return true
    allow(::Toggle::ElectricityPostpaidAutoswitch).to receive(:active?).and_return(true)
  end

  describe 'POST #inquiries' do
    before { http_login_new }

    let(:inquiry_response) {
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

    context 'when authenticate failed' do
      before { http_login('invalid_username', 'invalid_password') }

      let(:response) { post :inquiries, params: {} }

      it {
        expect(response.status).to eq(401)
      }
    end

    context 'when failing to provide customer number' do
      let(:response) { post :inquiries, params: {} }

      it {
        expect(response.status).to eq(422)
      }
    end

    context 'when failing to provide customer number' do
      let(:response) { post :inquiries, params: { customer_number: '1234567890' } }

      it {
        expect(response.status).to eq(422)
      }
    end

    context 'when partner is unavailable' do
      let(:response) { post :inquiries, params: { customer_number: '123456789012' } }

      it {
        allow_any_instance_of(Form::ElectricityPostpaid).to receive(:partner_object).and_return(nil)
        expect(response.status).to eq(422)
      }
    end

    context 'when success inquiry' do
      let(:response) { post :inquiries, params: { customer_number: '123456789012' } }
      let(:partner_bukopin) { build_stubbed(:electricity_postpaid_partner, :bukopin) }

      it {
        expect(::Toggles::ElectricityPostpaidInternalUsePartner).to receive(:active?).and_return(false)
        allow_any_instance_of(Form::ElectricityPostpaid).to receive(:partner_object).and_return(partner_bukopin)
        expect_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:run!).and_return(inquiry_response)
        expect(response.status).to eq(200)
      }

      context 'when use alternate credential' do
        before { http_login_alt }

        it {
          expect(::Toggles::ElectricityPostpaidInternalUsePartner).to receive(:active?).and_return(false)
          allow_any_instance_of(Form::ElectricityPostpaid).to receive(:partner_object).and_return(partner_bukopin)
          expect_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:run!).and_return(inquiry_response)
          expect(response.status).to eq(200)
        }
      end
    end

    context 'when partner is specified' do
      context 'when electricity postpaid internal partner toggle is off' do
        let(:partner_bukopin) { build_stubbed(:electricity_postpaid_partner, :bukopin_bukaconnect) }
        let(:params) { { customer_number: '123456789012', partner: 'bukopin_bukaconnect' } }
        let(:response) { post :inquiries, params: params }

        before do
          expect(::Toggles::ElectricityPostpaidInternalUsePartner).to receive(:active?).and_return(false)
        end

        it 'uses active partner and run with no issue' do
          expect(::Form::ElectricityPostpaid).to receive(:new).with(params[:customer_number], Form::ElectricityPostpaid::DEFAULT_USERNAME, nil, anything).and_call_original
          expect(::ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_bukopin)
          expect_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:run!).and_return(inquiry_response)
          expect(response.status).to eq(200)
        end
      end

      context 'when electricity postpaid internal partner toggle is on' do
        let(:partner_bukopin) { build_stubbed(:electricity_postpaid_partner, :bukopin_bukaconnect) }
        let(:params) { { customer_number: '123456789012', partner: 'bukopin_bukaconnect' } }
        let(:response) { post :inquiries, params: params }

        before do
          expect(::Toggles::ElectricityPostpaidInternalUsePartner).to receive(:active?).and_return(true)
        end

        it 'uses specified partner and run with no issue' do
          expect(::Form::ElectricityPostpaid).to receive(:new).with(params[:customer_number], Form::ElectricityPostpaid::DEFAULT_USERNAME, params[:partner], anything).and_call_original
          expect(::ElectricityPostpaidPartner).to receive(:find_by).with(name: 'bukopin_bukaconnect').and_return(partner_bukopin)
          expect_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:run!).and_return(inquiry_response)
          expect(response.status).to eq(200)
        end
      end
    end
  end

  describe 'PATCH #status' do
    before do
      http_login_new
    end

    context 'transaction not found' do
      let(:params) {{ id: 1, status: 'succeed' }}
      it 'success the transaction' do
        expect(PostpaidTransaction).to receive(:find_by_id).and_return(nil)

        expect { post :status, params: params }.not_to raise_error
      end
    end

    context 'transaction_type: collecting_agent' do
      let(:middleman_callback) { double(Channel::Middleman::Callback, run!: true) }

      context 'when failing a pending transaction' do
        let(:params) {{ id: 1, status: 'failed' }}
        let(:transaction) { build(:postpaid_transaction_with_bill, :collecting_agent) }
        it 'expire the transaction' do
          expect(Channel::Middleman::Callback).to receive(:new).and_return(middleman_callback)
          expect(PostpaidTransaction).to receive(:find_by_id).and_return(transaction)

          expect { post :status, params: params }.not_to raise_error
          expect(transaction.state).to eq('expired')
        end
      end

      context 'when failing a paid transaction' do
        let(:params) {{ id: 1, status: 'failed' }}
        let(:transaction) { build(:postpaid_transaction_with_bill, :paid, :collecting_agent) }
        it 'fail the transaction' do
          expect(Channel::Middleman::Callback).to receive(:new).and_return(middleman_callback)
          expect(PostpaidTransaction).to receive(:find_by_id).and_return(transaction)

          expect { post :status, params: params }.not_to raise_error
          expect(transaction.state).to eq('failed')
        end
      end

      context 'when failing a processed transaction' do
        let(:params) {{ id: 1, status: 'failed' }}
        let(:transaction) { build(:postpaid_transaction_with_bill, :processed, :collecting_agent) }
        it 'fail the transaction' do
          expect(Channel::Middleman::Callback).to receive(:new).and_return(middleman_callback)
          expect(PostpaidTransaction).to receive(:find_by_id).and_return(transaction)

          expect { post :status, params: params }.not_to raise_error
          expect(transaction.state).to eq('failed')
        end
      end

      context 'when failing a partner_failed transaction' do
        let(:params) {{ id: 1, status: 'failed' }}
        let(:transaction) { build(:postpaid_transaction_with_bill, :partner_failed, :collecting_agent) }
        it 'fail the transaction' do
          expect(Channel::Middleman::Callback).to receive(:new).and_return(middleman_callback)
          expect(PostpaidTransaction).to receive(:find_by_id).and_return(transaction)

          expect { post :status, params: params }.not_to raise_error
          expect(transaction.state).to eq('failed')
        end
      end

      context 'when success a paid transaction' do
        let(:params) {{ id: 1, status: 'succeed' }}
        let(:transaction) { build(:postpaid_transaction_with_bill, :paid, :collecting_agent) }
        it 'success the transaction' do
          expect(Channel::Middleman::Callback).to receive(:new).and_return(middleman_callback)
          expect(PostpaidTransaction).to receive(:find_by_id).and_return(transaction)

          expect { post :status, params: params }.not_to raise_error
          expect(transaction.state).to eq('succeeded')
        end
      end

      context 'when success a processed transaction' do
        let(:params) {{ id: 1, status: 'succeed' }}
        let(:transaction) { build(:postpaid_transaction_with_bill, :processed, :collecting_agent) }
        it 'success the transaction' do
          expect(Channel::Middleman::Callback).to receive(:new).and_return(middleman_callback)
          expect(PostpaidTransaction).to receive(:find_by_id).and_return(transaction)

          expect { post :status, params: params }.not_to raise_error
          expect(transaction.state).to eq('succeeded')
        end
      end

      context 'when success a partner_succeeded transaction' do
        let(:params) {{ id: 1, status: 'succeed' }}
        let(:transaction) { build(:postpaid_transaction_with_bill, :partner_succeeded, :collecting_agent) }
        it 'success the transaction' do
          expect(Channel::Middleman::Callback).to receive(:new).and_return(middleman_callback)
          expect(PostpaidTransaction).to receive(:find_by_id).and_return(transaction)

          expect { post :status, params: params }.not_to raise_error
          expect(transaction.state).to eq('succeeded')
        end
      end

      context 'when expire a pending transaction' do
        let(:params) {{ id: 1, status: 'expired' }}
        let(:transaction) { build(:postpaid_transaction_with_bill, :collecting_agent) }
        it 'expire the transaction' do
          expect(Channel::Middleman::Callback).to receive(:new).and_return(middleman_callback)
          expect(PostpaidTransaction).to receive(:find_by_id).and_return(transaction)

          expect { post :status, params: params }.not_to raise_error
          expect(transaction.state).to eq('expired')
        end
      end

      context 'with unknown status' do
        let(:params) {{ id: 1, status: 'married' }}
        let(:transaction) { build(:postpaid_transaction_with_bill, :collecting_agent) }
        it 'expire the transaction' do
          expect(Channel::Middleman::Callback).not_to receive(:new)
          expect(PostpaidTransaction).to receive(:find_by_id).and_return(transaction)

          expect { post :status, params: params }.not_to raise_error
          expect(transaction.state).to eq('pending')
        end
      end
    end

    context 'transaction_type: normal' do
      context 'when success a partner_succeeded transaction' do
        let(:params) {{ id: 1, status: 'succeed' }}
        let(:transaction) { build(:postpaid_transaction_with_bill, :partner_succeeded) }
        it 'success the transaction' do
          expect(PostpaidTransaction).to receive(:find_by_id).and_return(transaction)

          expect { post :status, params: params }.not_to raise_error
          expect(transaction.state).to eq('succeeded')
        end
      end
    end
  end

  describe 'O2OVPE-271: POST #create' do
    before { http_login_new }

    let(:inquiry_response) {
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

    let(:params) {{ buyer_id: 1, customer_number: '520000000088' }}
    let(:response) { post :create, params: params }
    it {
      expect(::Toggles::ElectricityPostpaidInternalUsePartner).to receive(:active?).and_return(false)
      allow(::ElectricityPostpaidPartner).to receive(:find_by).and_return build(:electricity_postpaid_partner, :bukopin)
      allow_any_instance_of(::Action::ElectricityTransaction::Create).to receive(:save_transaction!).and_return build(:postpaid_transaction_with_bill)
      expect(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:new).with(params[:customer_number], buyer_type: BUKA_PENGADAAN_BUYER_TYPE).and_call_original
      expect_any_instance_of(Channel::Bukopin::ElectricityPostpaid::Requests::Inquiry).to receive(:run!).and_return(inquiry_response)
      expect(response.status).to eq(201)
    }

    context 'when invalid digit long' do
      let(:params) {{ buyer_id: '1', customer_number: '123456789123454578987', transaction_type: 'collecting_agent' }}

      it 'return invalid parameter error' do
        expect(response.status).to eq(422)
        expect(JSON.parse(response.body)["errors"].first["message"]).to eq('ID Pelanggan maks. 12 digit')
      end
    end

    context 'when customer number not provided' do
      let(:params) {{ buyer_id: '1', transaction_type: 'collecting_agent' }}

      it 'return invalid parameter error' do
        expect(response.status).to eq(422)
        expect(JSON.parse(response.body)["errors"].first["message"]).to eq('ID Pelanggan tidak boleh kosong')
      end
    end

    context 'when collecting agent transaction' do
      let(:params) {{ buyer_id: '1', customer_number: '520000000088', transaction_type: 'collecting_agent' }}

      before do
        allow_any_instance_of(Action::ElectricityTransaction::Create).to receive(:run!).and_return create(:postpaid_transaction_with_bill, :collecting_agent)
        expect(::Toggles::ElectricityPostpaidInternalUsePartner).to receive(:active?).and_return(false)
      end

      it 'create transaction with collecting_agent type' do
        expect(Form::ElectricityPostpaid).to receive(:new).with(params[:customer_number], anything, nil, 'collecting_agent', nil).and_call_original
        expect(Action::ElectricityTransaction::Create).to receive(:new).with(kind_of(Form::ElectricityPostpaid), params[:buyer_id], 'collecting_agent').and_call_original
        expect(response).to match_response_schema("internal/electricity_postpaid/create_transaction")
      end
    end

    context 'when partner is specified' do
      context 'when electricity postpaid internal partner toggle is off' do
        let(:partner_bukopin) { build_stubbed(:electricity_postpaid_partner, :bukopin_bukaconnect) }
        let(:params) { { buyer_id: '1', customer_number: '123456789012', partner: 'bukopin_bukaconnect', transaction_type: 'collecting_agent' } }
        let(:response) { post :create, params: params }

        before do
          expect(::Toggles::ElectricityPostpaidInternalUsePartner).to receive(:active?).and_return(false)
          allow_any_instance_of(Action::ElectricityTransaction::Create).to receive(:run!).and_return create(:postpaid_transaction_with_bill, :collecting_agent)
        end

        it 'uses active partner and run with no issue' do
          expect(::ElectricityPostpaidPartner).to receive(:find_by).with(state: 'active').and_return(partner_bukopin)
          expect(::Form::ElectricityPostpaid).to receive(:new).with(params[:customer_number], Form::ElectricityPostpaid::DEFAULT_USERNAME, nil, anything, nil).and_call_original
          expect(Action::ElectricityTransaction::Create).to receive(:new).with(kind_of(Form::ElectricityPostpaid), params[:buyer_id], 'collecting_agent').and_call_original
          expect(response.status).to eq(201)
        end
      end

      context 'when electricity postpaid internal partner toggle is on' do
        let(:partner_bukopin) { build_stubbed(:electricity_postpaid_partner, :bukopin_bukaconnect) }
        let(:params) { { buyer_id: '1', customer_number: '123456789012', partner: 'bukopin_bukaconnect', transaction_type: 'collecting_agent' } }
        let(:response) { post :create, params: params }

        before do
          expect(::Toggles::ElectricityPostpaidInternalUsePartner).to receive(:active?).and_return(true)
          allow_any_instance_of(Action::ElectricityTransaction::Create).to receive(:run!).and_return create(:postpaid_transaction_with_bill, :collecting_agent)
        end

        it 'uses specified partner and run with no issue' do
          expect(::ElectricityPostpaidPartner).to receive(:find_by).with(name: 'bukopin_bukaconnect').and_return(partner_bukopin)
          expect(::Form::ElectricityPostpaid).to receive(:new).with(params[:customer_number], Form::ElectricityPostpaid::DEFAULT_USERNAME, params[:partner], anything, nil).and_call_original
          expect(Action::ElectricityTransaction::Create).to receive(:new).with(kind_of(Form::ElectricityPostpaid), params[:buyer_id], 'collecting_agent').and_call_original
          expect(response.status).to eq(201)
        end
      end
    end

    context 'when mass bill transaction' do
      let(:mass_bill_id) { SecureRandom.uuid }
      let(:params) {{ buyer_id: '1', customer_number: '520000000088', mass_bill_id: mass_bill_id }}

      before do
        allow_any_instance_of(Action::ElectricityTransaction::Create).to receive(:run!).and_return build_stubbed(:postpaid_transaction_with_bill, :with_mass_bill)
        expect(::Toggles::ElectricityPostpaidInternalUsePartner).to receive(:active?).and_return(false)
      end

      it 'returns http success' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(201)
      end

      it 'create transaction with mass bill' do
        expect(Form::ElectricityPostpaid).to receive(:new).with(params[:customer_number], anything, nil, anything, mass_bill_id).and_call_original
        expect(Action::ElectricityTransaction::Create).to receive(:new).with(kind_of(Form::ElectricityPostpaid), params[:buyer_id], anything).and_call_original
        expect(response).to match_response_schema("internal/electricity_postpaid/create_transaction")
      end
    end
  end

  describe 'GET #show' do
    before { http_login_new }

    let(:transaction) { create(:postpaid_transaction_with_bill) }
    let(:params) {{ id: 1 }}
    let(:response) { get :show, params: params }

    context 'when transaction found' do
      before {
        allow(::PostpaidTransaction).to receive(:find_by_id).and_return transaction
      }
      it {
        expect(response).to match_response_schema("internal/electricity_postpaid/get_transaction")
        expect(response.status).to eq(200)
      }
    end

    context 'when transaction not found' do
      before {
        allow(::PostpaidTransaction).to receive(:find_by_id).and_return nil
      }
      it {
        expect(response.status).to eq(404)
      }
    end
  end

  describe 'POST #resend_email' do
    before { http_login_new }

    let(:transaction) { build(:postpaid_transaction_with_bill, :succeeded) }
    let(:params) {{ remote_transaction_id: 1 }}
    let(:response) { post :resend_email, params: params }

    context 'when transaction found' do
      it {
        allow(::PostpaidTransaction).to receive(:find_by).and_return transaction
        expect(::GcpsPublisher).to receive(:publish).with(Subscribers::Topics::EMAIL_NOTIF, kind_of(Hash), track_id: transaction.remote_transaction_id).and_return true
        expect(response.status).to eq(202)
      }
    end

    context 'when transaction not found' do
      it {
        allow(::PostpaidTransaction).to receive(:find_by).and_return nil
        expect(response.status).to eq(404)
      }
    end

    context 'when transaction state not succeeded' do
      let(:transaction) { build(:postpaid_transaction_with_bill) }
      it {
        allow(::PostpaidTransaction).to receive(:find_by).and_return transaction
        expect(response.status).to eq(422)
      }
    end
  end

  describe 'GET #get_partners' do
    before { http_login_new }

    let(:partner_sepulsa) { create(:electricity_postpaid_partner, :sepulsa, :inactive) }
    let(:partner_bukopin) { create(:electricity_postpaid_partner, :bukopin, :active) }
    let(:partner_tektaya) { create(:electricity_postpaid_partner, :tektaya, :active) }
    let(:partners) { [ partner_sepulsa, partner_bukopin, partner_tektaya ] }

    let(:response) { get :get_partners }

    context 'when eligible partner existed' do
      before do
        expect(ElectricityPostpaidPartner).to receive(:all).and_return(partners)
      end

      it 'returns list of eligible partner' do
        expect(response).to match_response_schema("internal/electricity_postpaid/get_partners")
        hash_body = JSON.parse(response.body)
        expect(hash_body['data'].count).to eq(3)
        expect(response.status).to eq(HTTP_STATUS_OK)
      end
    end

    context 'when there is no eligible partner' do
      let(:partners) { [] }

      before do
        expect(ElectricityPostpaidPartner).to receive(:all).and_return(partners)
      end

      it 'returns empty array data' do
        hash_body = JSON.parse(response.body)
        expect(hash_body['data'].count).to eq(0)
        expect(response.status).to eq(HTTP_STATUS_OK)
      end
    end
  end
end
