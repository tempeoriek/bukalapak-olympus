require 'rails_helper'
require 'support/pdam_mocks'

RSpec.describe Action::PdamTransaction::UpdateStatus, type: :model do
  include_context 'pdam_mocks'

  subject { described_class.new(pdam_transaction, response_generalizer) }

  before do
    allow_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!).and_return true
    allow_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!).and_return true
  end

  describe 'O2OVPD-1589: #run!' do
    context 'when response status is success' do
      let(:response_generalizer) { success_response }

      context 'with partner Sepulsa' do
        it { expect { subject.run! }.not_to raise_error }
        it 'have expected attributes' do
          transaction = subject.run!
          expect(transaction.state).to eq('partner_succeeded')
          expect(transaction.partner_transaction_id).to eq '1'
          expect(transaction.address).to eq 'Jakarta'
          expect(transaction.pdam_bills.length).to eq 2
        end
      end

      context 'with partner MKM' do
        let(:mkm_operator) { build_stubbed(:pdam_operator, :mkm_thor) }
        let(:pdam_transaction) { build(:pdam_transaction_with_bill, :partner_mkm_thor, :processed) }

        before do
          allow(pdam_transaction).to receive(:operator).and_return(mkm_operator)
        end

        it { expect { subject.run! }.not_to raise_error }
        it 'have expected attributes' do
          transaction = subject.run!
          expect(transaction.state).to eq('partner_succeeded')
          expect(transaction.partner_transaction_id).to eq '1'
          expect(transaction.address).to eq 'Jakarta'
          expect(transaction.pdam_bills.length).to eq 2
          expect(transaction.details).to have_key('sub_segment')
          expect(transaction.details).to have_key('biller_ref')
        end
      end

      context 'with address already present in pdam transaction' do
        let(:pdam_transaction) { build(:pdam_transaction_with_bill, :address_present, :processed) }

        context 'with address present in response' do
          it { expect { subject.run! }.not_to raise_error }
          it 'have expected attributes' do
            transaction = subject.run!
            expect(transaction.state).to eq('partner_succeeded')
            expect(transaction.partner_transaction_id).to eq '1'
            expect(transaction.pdam_bills.length).to eq 2
            expect(transaction.address).to eq 'Jakarta'
          end
        end

        context 'with address is not present in response' do
          let(:response_generalizer) do
            response = success_response
            response.address = nil
            response
          end

          it { expect { subject.run! }.not_to raise_error }
          it 'have expected attributes' do
            transaction = subject.run!
            expect(transaction.state).to eq('partner_succeeded')
            expect(transaction.partner_transaction_id).to eq '1'
            expect(transaction.pdam_bills.length).to eq 2
            expect(transaction.address).to eq 'This address'
          end
        end
      end
    end

    context 'when response status is failed' do
      let(:response_generalizer) { failed_response }
      it { expect { subject.run! }.not_to raise_error }
      it { expect(subject.run!.state).to eq('partner_failed') }
    end

    context 'when response status is neither success nor failed' do
      let(:response_generalizer) { pending_response }
      it { expect { subject.run! }.to raise_error(Exceptions::InvalidStatusError) }
    end
  end
end
