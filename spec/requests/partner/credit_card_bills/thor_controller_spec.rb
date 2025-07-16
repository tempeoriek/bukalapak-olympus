require "rails_helper"
include AuthHelper

RSpec.describe Partner::CreditCardBills::ThorController, type: :controller do
  let(:transaction) {
    build(:cc_transaction, :succeeded, :visa)
  }
  let(:params){
    {
      "reference_number": "702209070945101598",
      "financial_journal_number": "24325513",
      "journal_number": "56632111",
      "order_id": "CC-1",
      "response_code": "0000",
      "message": "successful", 
    }
  }

  describe 'O2OVPE-1566 POST #callbacks' do
    context 'with right authentication' do
      before do
        http_login(ENV['THOR_CALLBACK_USERNAME'], ENV['THOR_CALLBACK_PASSWORD'])
        allow(Action::CreditCardBillTransaction::Callbacks::Thor).to receive_message_chain(:new, :run!) { transaction }
      end

      it 'should return http Success 200' do
        post :callbacks, params: { credit_card_bill_transaction: params }
        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end

    context 'with wrong authentication' do
      before do
        http_login('wrongusername', 'wrongpassword')
      end

      it 'should return Unauthorized 401' do
        post :callbacks, params: { credit_card_bill_transaction: params }
        expect(response).to have_http_status(:unauthorized)
        expect(response.status).to eq(401)
      end
    end

    context 'when rescue Exceptions::InvalidStatusError' do
      before do
        http_login(ENV['THOR_CALLBACK_USERNAME'], ENV['THOR_CALLBACK_PASSWORD'])
        allow(Action::CreditCardBillTransaction::Callbacks::Thor).to receive_message_chain(:new, :run!).and_raise(::Exceptions::InvalidStatusError)
      end

      it 'should return OK 200' do
        post :callbacks, params: { credit_card_bill_transaction: params }

        expect(response).to have_http_status(:success)
        expect(response.status).to eq(200)
      end
    end
  end
end
