require "rails_helper"

RSpec.describe Internal::BackgroundJobs::PostpaidController, type: :controller do
  include AuthHelper
  include Authenticate
  include PostpaidTransactionUtility

  let(:pending_trx) { build_stubbed(:postpaid_transaction_with_bill, :pending) }
  let(:paid_trx) { build_stubbed(:postpaid_transaction_with_bill, :paid) }
  let(:processed_trx) { build_stubbed(:postpaid_transaction_with_bill, :processed) }
  let(:succeeded_trx) { build_stubbed(:postpaid_transaction_with_bill, :succeeded) }
  let(:failed_trx) { build_stubbed(:postpaid_transaction_with_bill, :failed) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow_any_instance_of(Authenticate).to receive(:http_basic_authenticate).and_return true
  end

  describe 'POST #transaction_create' do
    context 'when normal flow' do
      let(:payload) {{
        transaction_id: paid_trx.id,
        product: ELECTRICITY_PRODUCT,
      }}

      before do
        allow_any_instance_of(PostpaidTransactionUtility).to receive(:find_transaction_by).and_return(paid_trx)
      end

      it 'should run PartnerCreate when calling api' do
        expect_any_instance_of(Action::PostpaidTransaction::PartnerCreate).to receive(:run!)
        post :transaction_create, params: payload
      end

      it 'should not raise error' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'POST #transaction_confirm' do

    context 'when normal flow (trx is `processed`)' do
      let(:payload) {{
        transaction_id: processed_trx.id,
        product: ELECTRICITY_PRODUCT,
      }}

      before do
        allow_any_instance_of(PostpaidTransactionUtility).to receive(:find_transaction_by).and_return(processed_trx)
      end

      it 'should run Confirm' do
        expect_any_instance_of(Action::PostpaidTransaction::Confirm).to receive(:run!)
        post :transaction_confirm, params: payload
      end

      it 'should not raise error' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end

    context 'when trx is `pending`' do
      let(:payload) {{
        transaction_id: pending_trx.id,
        product: ELECTRICITY_PRODUCT,
      }}

      before do
        allow_any_instance_of(PostpaidTransactionUtility).to receive(:find_transaction_by).and_return(pending_trx)
      end

      it 'should not run Confirm' do
        expect_any_instance_of(Action::PostpaidTransaction::Confirm).not_to receive(:run!)
        post :transaction_confirm, params: payload
      end

      it 'should not raise error' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end

    context 'when trx is final state' do
      let(:payload) {{
        transaction_id: succeeded_trx.id,
        product: ELECTRICITY_PRODUCT,
      }}

      before do
        allow_any_instance_of(PostpaidTransactionUtility).to receive(:find_transaction_by).and_return(succeeded_trx)
      end

      it 'should not run Confirm' do
        expect_any_instance_of(Action::PostpaidTransaction::Confirm).not_to receive(:run!)
        post :transaction_confirm, params: payload
      end

      it 'should not raise error' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end

  end

  describe 'POST #transaction_send_email' do
    context 'when normal flow' do
      let(:payload) {{
        transaction_id: succeeded_trx.id,
        product: ELECTRICITY_PRODUCT,
      }}

      before do
        allow_any_instance_of(PostpaidTransactionUtility).to receive(:find_transaction_by).and_return(succeeded_trx)
      end

      it 'should run Escrow::SendNotification when calling api' do
        expect_any_instance_of(Escrow::SendNotification).to receive(:run!)
        post :transaction_send_email, params: payload
      end

      it 'should not raise error' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'POST #transaction_update_remote' do
    context 'when normal flow' do
      let(:payload) {{
        transaction_id: succeeded_trx.id,
        product: ELECTRICITY_PRODUCT,
      }}

      before do
        allow_any_instance_of(PostpaidTransactionUtility).to receive(:find_transaction_by).and_return(succeeded_trx)
      end

      it 'should run Escrow::UpdateTransactionStatus when calling api' do
        expect_any_instance_of(Escrow::UpdateTransactionStatus).to receive(:run!)
        post :transaction_update_remote, params: payload
      end

      it 'should not raise error' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'POST #transaction_callback_sepulsa' do
    context 'when normal flow' do
      let(:payload) {{
        order_id: processed_trx.order_id,
        product: ELECTRICITY_PRODUCT,
      }}
      let(:response_generalizer) { ResponseGeneralizer::ElectricityPostpaid.new(nil, nil) }

      before do
        allow_any_instance_of(PostpaidTransactionUtility).to receive(:find_transaction_by).and_return(processed_trx)
        allow_any_instance_of(PostpaidTransactionUtility)
          .to receive(:update_transaction_status_action_object)
          .and_return(Action::ElectricityTransaction::UpdateStatus.new(processed_trx, response_generalizer))
        allow_any_instance_of(SepulsaGeneralizeable).to receive(:sepulsa_response_generalizer).and_return(response_generalizer)
      end

      it 'should call update status' do
        expect_any_instance_of(Action::ElectricityTransaction::UpdateStatus).to receive(:run!)
        post :transaction_callback_sepulsa, params: payload
      end

      it 'should not raise error' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end
  end

  describe 'O2OVPE-2375: POST #user_deleted' do
  before { http_login_new }

  let(:user_id) { '123' }
  let(:params) do
    {
      actor_id: '1',
      user_id: user_id,
      username: "someusername",
      name: 'some name',
      email: "some@email.test",
      confirmed: false,
      phone: '6281000000',
      phone_confirmed: false
    }
  end
  let(:response) { post :user_deleted, params: params }

  context 'when successfully deleted_user' do
    before do
      run = double
      allow(Services::AnonymizationData).to receive(:new).with(user_id).and_return(run)
      allow(run).to receive(:perform).and_return(true)
    end

    it { expect(response.status).to eq(200) }
  end

  context 'when invalid params' do
    let(:user_id) { '' }

    it { expect(response.status).to eq(422) }
  end
end

end
