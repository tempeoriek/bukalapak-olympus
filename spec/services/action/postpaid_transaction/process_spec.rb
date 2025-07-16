require "rails_helper"

RSpec.describe Action::PostpaidTransaction::Process, type: :model do
  include Postpaid::Constant

  subject {Action::PostpaidTransaction::Process.new(transaction).run!}

  before { allow(Toggles::OlympusSievexSend).to receive(:active?) { true } }
  before { allow(Toggles::OlympusSievexPredict).to receive(:active?) { false } }

  context "electricity" do
    context "failed" do
      context 'pending' do
        let(:transaction) { create(:postpaid_transaction_with_bill, :succeeded, :partner_sepulsa) }
        it "should raise error if transaction state may not process" do
          expect { subject }.to raise_error(::Exceptions::CannotProcessTransaction)
        end
      end

      context 'partner_transaction_id not nil' do
        let(:transaction) { create(:postpaid_transaction_with_bill, :processed, :partner_sepulsa, partner_transaction_id: "1234") }
        it "should raise error" do
          expect { subject }.to raise_error(::Exceptions::CannotProcessTransaction)
        end
      end
    end

    context 'success' do
      context 'pending' do
        let(:transaction) { create(:postpaid_transaction_with_bill, :pending, :partner_sepulsa, partner_transaction_id: nil) }
        it "should not raise error and spawn job if transaction state may process" do
          expect(::GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS, any_args)
          expect { subject}.to_not raise_error
        end
      end

      context 'partner_transaction_id is nil' do
        let(:transaction) { create(:postpaid_transaction_with_bill, :paid, :partner_sepulsa, partner_transaction_id: nil) }
        it "should not raise error" do
          expect(::GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS, any_args)
          expect { subject }.not_to raise_error
        end
      end

      context 'when transaction type is agent' do
        let(:transaction) { create(:postpaid_transaction_with_bill, :pending, :partner_sepulsa, :agent, partner_transaction_id: nil) }
        it 'sends notification' do
          expect_any_instance_of(::Action::PostpaidTransaction::SendNotification).to receive(:run!).and_return true
          expect { subject}.to_not raise_error
        end
      end
    end
  end

  context "bpjs_kesehatan" do
    context "failed" do
      context 'pending' do
        let(:transaction) { create(:bpjs_kesehatan_transaction, state: 'succeeded') }
        it "should raise error if transaction state may not process" do
          expect { subject }.to raise_error(::Exceptions::CannotProcessTransaction)
        end
      end

      context 'partner_transaction_id not nil' do
        let(:transaction) { create(:bpjs_kesehatan_transaction, state: 'processed', partner_transaction_id: "1234") }
        it "should raise error" do
          expect { subject }.to raise_error(::Exceptions::CannotProcessTransaction)
        end
      end
    end

    context 'success' do
      context 'pending' do
        let(:transaction) { create(:bpjs_kesehatan_transaction, state: 'pending', partner_transaction_id: nil) }
        it "should not raise error and spawn job if transaction state may process" do
          expect(::GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS, any_args)
          expect { subject}.to_not raise_error
        end
      end

      context 'partner_transaction_id is nil' do
        let(:transaction) { create(:bpjs_kesehatan_transaction, state: 'paid', partner_transaction_id: nil) }
        it "should not raise error" do
          expect(::GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS, any_args)
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  context "pdam" do
    context "failed" do
      context 'pending' do
        let(:transaction) { create(:pdam_transaction_with_bill, state: 'succeeded') }
        it "should raise error if transaction state may not process" do
          expect { subject }.to raise_error(::Exceptions::CannotProcessTransaction)
        end
      end

      context 'partner_transaction_id not nil' do
        let(:transaction) { create(:pdam_transaction_with_bill, state: 'processed', partner_transaction_id: "1234") }
        it "should raise error if transaction state may not process" do
          expect { subject }.to raise_error(::Exceptions::CannotProcessTransaction)
        end
      end
    end

    context 'success' do
      context 'pending' do
        let(:transaction) { create(:pdam_transaction_with_bill, state: 'pending', partner_transaction_id: nil) }
        it "should not raise error and spawn job if transaction state may process" do
          expect(::GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS, any_args)
          expect { subject}.to_not raise_error
        end
      end

      context 'partner_transaction_id is nil' do
        let(:transaction) { create(:pdam_transaction_with_bill, state: 'paid', partner_transaction_id: nil) }
        it "should raise error" do
          expect(::GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS, any_args)
          expect { subject }.not_to raise_error
        end
      end
    end
  end

  context 'credit card bill' do
    context 'success' do
      context 'pending' do
        let(:transaction) { create(:cc_transaction, :pending) }

        before {
          allow(GeneralCircuitBreaker::CreditCardBill.instance).to receive(:incr).with(transaction.amount).and_return(true)
        }

        context 'when OlympusSievexPredict toggle off' do
          it "should not raise error and spawn job if transaction state may process" do
            expect(::GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS_CREDIT_CARD_BILL, any_args)
            expect { subject }.to_not raise_error
          end
        end

        context 'when OlympusSievexPredict toggle on' do
          before {
            allow(Toggles::OlympusSievexPredict).to receive(:active?).and_return true
            allow_any_instance_of(Sievex::Send).to receive(:run!).and_return true
          }
          it 'publishes SIEVEX_PREDICT job' do
            expect(::GcpsPublisher).to receive(:publish).with(Subscribers::Topics::SIEVEX_PREDICT, any_args)
            expect { subject }.to_not raise_error
          end

          context 'using wiremock' do
            let(:transaction) { create(:cc_transaction, :visa, :pending_visa) }

            it 'publishes PARTNER_PROCESS_CREDIT_CARD_BILL job' do
              stub_const('Channel::Config::VISA_WIREMOCK', 'localhost')
              expect(::GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS_CREDIT_CARD_BILL, any_args)
              expect { subject }.to_not raise_error
            end
          end
        end
      end
    end
  end
end
