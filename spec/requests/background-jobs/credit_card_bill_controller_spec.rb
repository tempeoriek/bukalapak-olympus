require "rails_helper"

RSpec.describe Internal::BackgroundJobs::CreditCardBillController, type: :controller do
  include AuthHelper
  include Authenticate
  include PostpaidTransactionUtility

  let(:pending_trx) { build_stubbed(:cc_transaction, :pending) }
  let(:paid_trx) { build_stubbed(:cc_transaction, :paid) }
  let(:processed_trx) { build_stubbed(:cc_transaction, :processed) }
  let(:succeeded_trx) { build_stubbed(:cc_transaction, :succeeded) }
  let(:failed_trx) { build_stubbed(:cc_transaction, :failed) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:trace_latency).and_return true
    allow_any_instance_of(ApplicationController).to receive(:request_status).and_return 'ok'
    allow_any_instance_of(Authenticate).to receive(:http_basic_authenticate).and_return true
  end

  describe 'POST #transaction_create' do
    let(:payload) {{
      transaction_id: paid_trx.id,
      product: CREDIT_CARD_BILL_PRODUCT,
    }}

    context 'when normal flow' do
      before do
        allow_any_instance_of(PostpaidTransactionUtility).to receive(:find_transaction_by).and_return(paid_trx)
      end

      it 'should run PartnerCreate when calling api' do
        expect_any_instance_of(Action::CreditCardBillTransaction::PartnerCreate).to receive(:run!)
        post :transaction_create, params: payload
      end

      it 'should not raise error' do
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end

    context 'when connection error' do
      it {
        allow_any_instance_of(PostpaidTransactionUtility).to receive(:find_transaction_by).and_return(paid_trx)
        allow_any_instance_of(Action::CreditCardBillTransaction::PartnerCreate).to receive(:run!).and_raise Errno::ECONNREFUSED
        post :transaction_create, params: payload
        expect(response.status).to eq(502)
      }
    end
  end

end
