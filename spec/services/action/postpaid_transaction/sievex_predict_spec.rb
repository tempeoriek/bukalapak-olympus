require "rails_helper"

RSpec.describe Action::PostpaidTransaction::SievexPredict, type: :model do
  let(:transaction) { create(:cc_transaction, :paid) }
  let(:track_response) { { message: 'Request is successfully processed' } }
  let(:predict_response) {{
    data: {
      suggestion: 'NORMAL',
      categories: [{
        category_id: 18,
        name: "TS User Registration",
        suggestion: "NORMAL",
        scores: [],
        rule_hits: [{
            rule_id: "5ca72c988e017300218de770",
            rule_name: "Tendency Bot Registration"
        }, {
            rule_id: "5cb59891a9ac60001b57bed7",
            rule_name: "Tendency Bot Registration UA35"
        }]
      }]
    }
  }}

  before do
    allow(SieveX::Client).to receive(:predict) { sievex_response(200, predict_response) }
    allow(SieveX::Client).to receive(:track) { sievex_response(201, track_response) }
    allow(Toggles::OlympusSievexSend).to receive(:active?) { true }
  end

  describe '#run!' do
    before do
      expect(Toggles::OlympusSievexAction).to receive(:active?) { false }
      expect(::GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS_CREDIT_CARD_BILL, hash_including(product_type: transaction.product_type), anything)
    end

    subject { described_class.new(transaction) }

    context 'when transaction paid' do
      it { expect { subject.run! }.not_to raise_error }
    end
  end

  def sievex_response(status, data)
    SieveX::Response.new(nil, nil, data.to_json)
  end

  context 'when action toggle inactive' do
    let(:predict_response) {{
      data: {
        suggestion: 'FRAUD',
        categories: [{
          category_id: 18,
          name: "TS User Registration",
          suggestion: "FRAUD",
          scores: [],
          rule_hits: [{
              rule_id: "5ca72c988e017300218de770",
              rule_name: "Tendency Bot Registration"
          }, {
              rule_id: "5cb59891a9ac60001b57bed7",
              rule_name: "Tendency Bot Registration UA35"
          }]
        }]
      }
    }}

    before do
      expect(Toggles::OlympusSievexAction).to receive(:active?) { false }
      expect(::GcpsPublisher).to receive(:publish).with(Subscribers::Topics::PARTNER_PROCESS_CREDIT_CARD_BILL, hash_including(product_type: transaction.product_type), anything)
    end

    subject { described_class.new(transaction) }

    it 'publish job as usual' do
      expect{ subject.run! }.not_to raise_error
    end
  end

  context 'when action toggle active' do
    let(:sievex_action_log) { build(:sievex_action_log) }
    let(:predict_response) {{
      data: {
        suggestion: 'FRAUD',
        categories: [{
          category_id: 18,
          name: "TS User Registration",
          suggestion: "FRAUD",
          scores: [],
          rule_hits: [{
              rule_id: "5ca72c988e017300218de770",
              rule_name: "Tendency Bot Registration"
          }, {
              rule_id: "5cb59891a9ac60001b57bed7",
              rule_name: "Tendency Bot Registration UA35"
          }]
        }]
      }
    }}

    let(:log_params) do
      {
        entity_id: 1,
        entity_type: 'credit_card_bill_transaction',
        actor: 'system',
        reason: 'TS User Registration'
      }
    end

    let(:metric_params) do
      {
        product_type: ::Postpaid::Constant::CREDIT_CARD_BILL_PRODUCT,
        suggestion: 'FRAUD',
        reason: 'TS User Registration'
      }
    end

    before do
      expect(Toggles::OlympusSievexAction).to receive(:active?) { true }
      expect_any_instance_of(Action::PostpaidTransaction::UpdateRemote).to receive(:run!)
      expect_any_instance_of(Action::PostpaidTransaction::SendNotification).to receive(:run!)
    end

    subject { described_class.new(transaction) }

    it 'publish cancel and refund the transaction' do
      expect(::SievexActionLog).to receive(:new).with(log_params).and_return(sievex_action_log)
      expect_any_instance_of(::SievexActionLog).to receive(:save!)
      expect(::Observer).to receive(:counter).with(Observer::Metric::STATE, 1, anything).twice
      expect(::Observer).to receive(:counter).with(Observer::Metric::SIEVEX, 1, metric_params)
      expect{ subject.run! }.not_to raise_error
      expect(transaction.state).to eq 'cancelled'
    end
  end
end
