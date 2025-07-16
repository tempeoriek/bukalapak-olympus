require 'rails_helper'

RSpec.describe Action::PostpaidTransaction::ForceUpdateStatus, type: :model do

  describe '.run!' do
    subject { described_class.new(transaction, status).run! }
    let(:send_notification) { double(Action::PostpaidTransaction::SendNotification, run!: true) }
    let(:middleman_channel) { double(Channel::Middleman::Callback, run!: true) }

    context 'when status is success' do
      let(:transaction) { create(:postpaid_transaction_with_bill, :processed, :collecting_agent) }
      let(:status) { 'succeed' }

      it 'does not raise error and update transaction status' do
        expect(Action::PostpaidTransaction::SendNotification).to receive(:new).and_return(send_notification)
        expect(Channel::Middleman::Callback).to receive(:new).and_return(middleman_channel)
        expect { subject }.not_to raise_error

        expect(transaction.state).to eq('succeeded')
      end

      context 'normal transaction type' do
        let(:transaction) { create(:postpaid_transaction_with_bill, :processed) }

        it 'does not raise error and update transaction status' do
          expect(Action::PostpaidTransaction::SendNotification).to receive(:new).and_return(send_notification)
          expect(Channel::Middleman::Callback).not_to receive(:new)
          expect { subject }.not_to raise_error

          expect(transaction.state).to eq('succeeded')
        end
      end
    end

    context 'when status is expired' do
      let(:transaction) { create(:postpaid_transaction_with_bill, :processed, :collecting_agent) }
      let(:status) { 'expired' }

      context 'transaction is at processed state' do
        it 'raises error' do
          expect { subject }.to raise_error(AASM::InvalidTransition)
        end
      end

      context 'transaction is at pending state' do
        let(:transaction) { create(:postpaid_transaction_with_bill, :pending, :collecting_agent) }

        it 'does not raise error and update transaction status' do
          expect(Channel::Middleman::Callback).to receive(:new).and_return(middleman_channel)
          expect(Action::PostpaidTransaction::SendNotification).not_to receive(:new)
          expect { subject }.not_to raise_error

          expect(transaction.state).to eq('expired')
        end
      end

    end

    context 'when status is failed' do
      let(:transaction) { create(:postpaid_transaction_with_bill, :processed, :collecting_agent) }
      let(:status) { 'failed' }

      context 'transaction is at processed state' do
        it 'does not raise error and update transaction status' do
          expect(Channel::Middleman::Callback).to receive(:new).and_return(middleman_channel)
          expect(Action::PostpaidTransaction::SendNotification).to receive(:new).and_return(send_notification)
          expect { subject }.not_to raise_error

          expect(transaction.state).to eq('failed')
        end
      end

      context 'transaction is at pending state' do
        let(:transaction) { create(:postpaid_transaction_with_bill, :pending, :collecting_agent) }

        it 'does not raise error and update transaction status' do
          expect(Channel::Middleman::Callback).to receive(:new).and_return(middleman_channel)
          expect(Action::PostpaidTransaction::SendNotification).not_to receive(:new)
          expect { subject }.not_to raise_error

          expect(transaction.state).to eq('expired')
        end
      end
    end

    context 'O2OVPE-845: when pdam transaction' do
      context 'paid transaction failed' do
        let(:transaction) { create(:pdam_transaction_with_bill, :paid) }
        let(:status) { 'failed' }

        it 'record failed autoswitch value' do
          expect { subject }.not_to raise_error

          expect(transaction.state).to eq('failed')
        end
      end
    end

    context 'O2OVPE-1674: when electricity transaction' do
      context 'paid transaction failed' do
        let(:transaction) { create(:postpaid_transaction_with_bill, :paid, ) }
        let(:status) { 'failed' }

        it 'record failed autoswitch value' do
          expect { subject }.not_to raise_error

          expect(transaction.state).to eq('failed')
        end
      end
    end
  end
end
