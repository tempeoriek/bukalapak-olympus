require 'rails_helper'
include AuthHelper

RSpec.describe Internal::BpjsKetenagakerjaanController, type: :controller do
  let(:transaction) { build(:bpjs_ketenagakerjaan_transaction, id: 14_923) }

  before do
    allow_any_instance_of(Authenticate).to receive(:http_basic_authenticate).and_return true
    allow_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).and_return true
    allow_any_instance_of(Sievex::Send).to receive(:run!).and_return true
    allow(GcpsPublisher).to receive(:publish).and_return true
    allow(RedisOlympus).to receive(:set).and_return true
    allow(RedisOlympus).to receive(:get).and_return 1
    allow(Toggles::OlympusSievexPredict).to receive(:active?).and_return false
  end

  describe '#confirm' do
    let(:response) { post :confirm, params: { id: 1 } }

    context 'when transaction found' do
      before { allow(::BpjsKetenagakerjaanTransaction).to receive(:find_by).and_return(transaction) }

      [:succeeded, :failed, :partner_succeeded, :partner_failed].each do |state|
        context "when transaction state is #{state}" do
          let(:transaction) { build_stubbed(:bpjs_ketenagakerjaan_transaction, state) }
          it {
            expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!)
            expect_any_instance_of(Action::PostpaidTransaction::Confirm).not_to receive(:run!)
            expect(response.status).to eq 200
          }
        end
      end

      context 'when transaction state is processed' do
        let(:transaction) { build_stubbed(:bpjs_ketenagakerjaan_transaction, :processed) }
          it {
            expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).not_to receive(:run!)
            expect_any_instance_of(Action::PostpaidTransaction::Confirm).to receive(:run!)
            expect(response.status).to eq 200
          }
      end

      [:pending, :paid, :expired, :cancelled].each do |state|
        context "when transaction state is #{state}" do
          let(:transaction) { build_stubbed(:bpjs_ketenagakerjaan_transaction, state) }
          it {
            expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).not_to receive(:run!)
            expect_any_instance_of(Action::PostpaidTransaction::Confirm).not_to receive(:run!)
            expect(response.status).to eq 422
          }
        end
      end
    end

    context 'when transaction not found' do
      it {
        allow(::BpjsKetenagakerjaanTransaction).to receive(:find_by).and_return nil
        expect(response.status).to eq 404
      }
    end
  end

  describe '#pay' do
    let(:response) { post :pay, params: { id: 1 } }

    context 'when transaction found' do
      it {
        allow(::BpjsKetenagakerjaanTransaction).to receive(:find_by).and_return transaction
        expect(response.status).to eq 200
      }
    end

    context 'when trx not found' do
      it {
        allow(::BpjsKetenagakerjaanTransaction).to receive(:find_by).and_return nil
        expect(response.status).to eq 404
      }
    end

    context 'with transaction wrong state or already processed with partner_transaction_id' do
      before { transaction.save! }

      [:succeeded, :failed, :partner_succeeded, :partner_failed].each do |state|
        context "when transaction state is #{state}" do
          let(:transaction) { build(:bpjs_ketenagakerjaan_transaction, state, id: 14_923) }
          it {
            allow(::BpjsKetenagakerjaanTransaction).to receive(:find_by).and_return transaction
            expect(response.status).to eq 200
          }
        end
      end

      context 'with transaction state is processed and have partner transaction id' do
        let(:transaction) { build(:bpjs_ketenagakerjaan_transaction, :processed, id: 14_923, partner_transaction_id: 1_001) }
        it {
          allow(::BpjsKetenagakerjaanTransaction).to receive(:find_by).and_return transaction
          expect(response.status).to eq 200
        }
      end
    end
  end

  describe 'O2OVPD-930: POST #invoicing' do
    let(:response) { post :invoicing, params: { id: 1 } }

    context 'when transaction found' do
      it {
        allow(::BpjsKetenagakerjaanTransaction).to receive(:find_by).and_return transaction
        expect(response.status).to eq 200
      }
    end

    context 'when transaction not found' do
      it {
        allow(::BpjsKetenagakerjaanTransaction).to receive(:find_by).and_return nil
        expect(response.status).to eq 404
      }
    end

    context 'when transaction invalid' do
      it {
        allow(::BpjsKetenagakerjaanTransaction).to receive(:find_by).and_return transaction
        allow_any_instance_of(Action::PostpaidTransaction::Invoicing).to receive(:run!).and_raise Exceptions::CreateTransactionError
        expect(response.status).to eq 422
      }
    end
  end

  describe 'O2OVPD-931: PATCH #status' do

    before {
      allow(::BpjsKetenagakerjaanTransaction).to receive(:find_by_id).and_return transaction
    }

    context 'when transaction state is already final' do
      [:succeeded, :failed].each do |state|
        context "when transaction state is #{state}" do
          let(:transaction) { build(:bpjs_ketenagakerjaan_transaction, state) }
          let(:response) { patch :status, params: { id: 1, status: 'succeed' } }
          it { expect(response.status).to eq 200 }
        end
      end
    end

    context 'when transaction state not final' do
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
        :cancelled => {
          'failed' =>  { action: :force_fail!,    http_status: 200 },
          'succeed' => { action: :force_success!, http_status: 200 },
          'expired' => { action: :expire!,        http_status: 200 }
        },
      }

      states_actions.each do |trx_state, to_state_actions|
        context "when transaction state is #{trx_state}" do
          to_state_actions.each do |to_state, state_action|
            context "when params[:status] is '#{to_state}'" do
              let(:transaction) { build(:bpjs_ketenagakerjaan_transaction, trx_state) }
              let(:response) { patch :status, params: { id: 1, status: to_state } }
              it {
                expect_any_instance_of(::BpjsKetenagakerjaanTransaction).to receive(state_action[:action])
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
        let(:transaction) { build(:bpjs_ketenagakerjaan_transaction, :processed) }
        let(:response) { patch :status, params: { id: 1, status: 'invalid' } }
        it {
          expect(response.status).to eq 422
        }
      end
    end
  end

  describe 'O2OVPD-1049: GET #show' do
    let(:response) { get :show, params: { id: 1 } }

    context 'when transaction found' do
      it {
        allow(::BpjsKetenagakerjaanTransaction).to receive(:find_by_id).and_return transaction
        expect(response.status).to eq 200
      }
    end

    context 'when transaction not found' do
      it {
        allow(::BpjsKetenagakerjaanTransaction).to receive(:find_by_id).and_return nil
        expect(response.status).to eq 404
      }
    end
  end
end
