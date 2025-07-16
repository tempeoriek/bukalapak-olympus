require "rails_helper"

RSpec.describe Recurrence::PhoneCreditPostpaid::InternalController, type: :controller do
  include AuthHelper
  let(:template) { build(:phone_credit_postpaid_recurrence_template_detail) }
  let(:trx) { build(:phone_credit_postpaid_transaction) }
  let(:provider) { build_stubbed(:phone_credit_provider) }

  before {
    allow_any_instance_of(described_class).to receive(:http_basic_authenticate).and_return true
    allow(PhoneCreditProvider).to receive(:find).and_return(provider)
  }

  describe 'POST #create' do
    before {
      allow_any_instance_of(Recurrence::PhoneCreditPostpaid::CreateTransaction).to receive(:run!).and_return trx
      post :create, params: { detail_id: 1 }
    }
    it {
      expect(response.status).to eq 201
    }
    it 'returns correct json' do
      hash_body = nil
      expect { hash_body = JSON.parse(response.body).with_indifferent_access }.not_to raise_error
      expect(hash_body[:data]).to include(:transaction_id, :amount)
    end
  end

  describe 'POST #notify_balance' do
    before {
      allow(Recurrence::PhoneCreditPostpaid::Notifier).to receive(:reminder).and_return true
    }
    context 'when template found' do
      it {
        allow(::PhoneCreditPostpaidRecurrenceTemplateDetail).to receive(:find_by_id!).and_return template
        post :notify_balance, params: { detail_id: 1 }
        expect(response.status).to eq(202)
      }
    end
    context 'when template not found' do
      it {
        allow(::PhoneCreditPostpaidRecurrenceTemplateDetail).to receive(:find_by_id!).and_return nil
        post :notify_balance, params: { detail_id: 1 }
        expect(response.status).to eq(404)
      }
    end
  end

  describe 'POST #notify_stop' do
    before {
      allow(Recurrence::PhoneCreditPostpaid::Notifier).to receive(:stop_subscribing).and_return true
    }
    context 'when template found' do
      it {
        allow(::PhoneCreditPostpaidRecurrenceTemplateDetail).to receive(:find_by_id!).and_return template
        post :notify_stop, params: { detail_id: 1 }
        expect(response.status).to eq(202)
      }
    end
    context 'when template not found' do
      it {
        allow(::PhoneCreditPostpaidRecurrenceTemplateDetail).to receive(:find_by_id!).and_return nil
        post :notify_stop, params: { detail_id: 1 }
        expect(response.status).to eq(404)
      }
    end
  end

end
