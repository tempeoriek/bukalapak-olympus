require "rails_helper"

RSpec.describe Action::CreditCardBillTransaction::PartnerCreate, type: :model do
  let(:push_notif_url) { "#{Channel::Config::TELOLET_URL}/_internal/publishers/push-notifications" }
  let(:onsite_notif_url) { "#{Channel::Config::TELOLET_URL}/_internal/publishers/onsite" }

  before {
    allow_any_instance_of(Channel::Visa::CreditCardBill).to receive(:create_transaction).and_return create_transaction_response
    allow_any_instance_of(Quickpays::Delete).to receive(:run!).and_return true
    allow(Toggles::OlympusSievexSend).to receive(:active?).and_return false
    allow(Toggles::EmailNotif).to receive(:active?).and_return true
    allow(Toggles::PushNotif).to receive(:active?).and_return true
    allow(Toggles::OnSiteNotif).to receive(:active?) { true }
    allow(::Toggle::CreditCardBill::WhitelistNewBNI).to receive(:active?).and_return(false)
    allow(Toggle::CreditCardBill::NewBNI).to receive(:active?).and_return(false)
    stub_request(:post, push_notif_url).to_return(status: 200, body: { status: 'OK' }.to_json)
    stub_request(:post, onsite_notif_url).to_return(status: 200, body: { status: 'OK' }.to_json)
  }

  subject { described_class.new(transaction) }

  describe '#run!' do
    context 'when partner is visa' do
      let(:biller) { create(:credit_card_biller, :visa, :partner_visa) }
      let(:transaction) {
        create(:cc_transaction, :paid_visa, credit_card_biller_id: biller.id, credit_card_bill_partner_id: biller.partner.id)
      }

      before {
        allow(Channel::Connection::Http).to receive(:delete).and_return true
      }

      context 'when success' do
        let(:create_transaction_response) {
          ResponseGeneralizer::CreditCardBill.new do |r|
            r.status = SUCCESS
            r.reference_number = '33557799'
            r.response_code = "VISA_00"
            r.partner_transaction_id = '5908718291286196503005'
          end
        }
        before {
          allow_any_instance_of(Channel::Visa::CreditCardBill).to receive(:create_transaction).and_return create_transaction_response
        }
        it 'calls DeleteToken action' do
          expect_any_instance_of(Action::CreditCardBillTransaction::DeleteToken).to receive(:run!).once
          subject.run!
        end
        it {
          subject.run!
          expect(transaction.state).to eq 'partner_succeeded'
        }
      end

      context 'when failed' do
        let(:create_transaction_response) {
          ResponseGeneralizer::CreditCardBill.new do |r|
            r.status = FAILED
            r.reference_number = '33557799'
            r.response_code = "VISA_NO_TOKEN"
            r.partner_transaction_id = '5908718291286196503005'
          end
        }
        before {
          allow_any_instance_of(Channel::Visa::CreditCardBill).to receive(:create_transaction).and_return create_transaction_response
        }
        it 'calls DeleteToken action' do
          expect_any_instance_of(Action::CreditCardBillTransaction::DeleteToken).to receive(:run!).once
          subject.run!
        end
        it {
          subject.run!
          expect(transaction.state).to eq 'partner_failed'
        }
      end

      context 'when timeout' do
        let(:create_transaction_response) {
          ResponseGeneralizer::CreditCardBill.new do |r|
            r.status = PROCESS
            r.reference_number = '33557799'
            r.response_code = 'timeout'
            r.partner_transaction_id = '5908718291286196503005'
          end
        }
        before {
          allow_any_instance_of(Channel::Visa::CreditCardBill).to receive(:create_transaction).and_return create_transaction_response
          allow(Toggles::Pubsub).to receive(:active?).and_return true
          allow(Toggles::Mws).to receive(:active?).and_return false
        }
        it 'calls DeleteToken action' do
          expect_any_instance_of(Action::CreditCardBillTransaction::DeleteToken).to receive(:run!).once
          subject.run!
        end
        it {
          subject.run!
          expect(transaction.state).to eq 'processed'
        }
        it {
          expect(GcpsPublisher).to receive(:publish).with(
            Subscribers::Topics::PARTNER_CONFIRM,
            kind_of(Hash),
            track_id: anything
          )
          subject.run!
        }
      end

    end

    context 'when partner is bni' do
      let(:transaction) { create(:cc_transaction, :paid) }

      context 'when success' do
        let(:create_transaction_response) {
          ResponseGeneralizer::CreditCardBill.new do |r|
            r.status = SUCCESS
            r.response_code = ::Postpaid::Constant::BNI_SUCCESS
            r.partner_journal_number = '123456789'
            r.partner_financial_journal_number = '123456'
          end
        }
        before {
          allow_any_instance_of(Channel::BNI::CreditCardBill).to receive(:create_transaction).and_return create_transaction_response
        }
        it {
          subject.run!
          expect(transaction.state).to eq 'partner_succeeded'
        }

        context 'when reference_number already exist' do
          let(:transaction) { create(:cc_transaction, :paid, reference_number: '123') }
          it {
            expect { subject.run! }.to raise_error(Exceptions::DoubleValueError)
          }
        end
      end

    end
  end

end
