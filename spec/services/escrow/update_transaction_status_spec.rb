require 'rails_helper'
require 'json'

RSpec.describe Escrow::UpdateTransactionStatus, type: :model do
  let(:transaction) { build(:postpaid_transaction_with_bill, :partner_succeeded) }
  let(:bpjs_kesehatan_partner) { build(:bpjs_kesehatan_partner) }
  let(:pdam_operator) { build(:pdam_operator, :sepulsa) }

  context 'request' do
    before do
      allow_any_instance_of(Escrow::UpdateTransactionStatus).to receive(:parse_response)
      allow_any_instance_of(::BpjsKesehatanTransaction).to receive(:partner_object).and_return bpjs_kesehatan_partner
      allow_any_instance_of(::PdamTransaction).to receive(:pdam_operator).and_return pdam_operator
    end

    it 'send correct payload' do
      object = Escrow::UpdateTransactionStatus.new(transaction)
      expect(Escrow::Connection).to receive(:patch).with(
        any_args,
        hash_including(
          remote_id: transaction.id,
          buyer_id: transaction.buyer_id,
          amount: transaction.amount,
          state: TRX_STATE_TO_BL_STATE_MAP[transaction.state]
        )
      )
      expect(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(
          action: 'refund_rate',
          status: :success
        ).and_return(double(run!: :noop))
      object.run!
    end

    transactions = {
      'credit-card-bill': { factories: :cc_transaction, additional_attr: {}, expected_revenue: 1000 },
      'bpjs-kesehatan': { factories: :bpjs_kesehatan_transaction, additional_attr: {}, expected_revenue: 1000 },
      'pdam': { factories: :pdam_transaction_with_bill, additional_attr: {}, expected_revenue: 2000 },
      'pdam_single_bill': { factories: :pdam_transaction_with_bill, additional_attr: { bills_count: 1 }, expected_revenue: 1000 }
    }

    transactions.each do |trx_type, scenario_detail|
      context "when trx is #{trx_type}" do
        let(:transaction) { build(scenario_detail[:factories], :partner_succeeded, scenario_detail[:additional_attr]) }

        before do
          transaction.paid_at = Time.now
          allow(Action::ElectricityAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return(:noop)
          allow(Action::PdamAutoswitch::Mechanism::Record).to receive_message_chain(:new, :run!).and_return(:noop)
        end

        it 'updates revenue and send metric when state is succeeded' do
          object = Escrow::UpdateTransactionStatus.new(transaction)
          expect(Observer).to receive(:histogram).with(
            Observer::Metric::SQL_LATENCY,
            anything,
            anything
          ).at_least(:once)

          expect(Observer).to receive(:histogram).with(
            Observer::Metric::TIME_TO_SUCCEED,
            anything,
            anything
          ).and_return(true)

          expect(Escrow::Connection).to receive(:patch).with(
            any_args,
            hash_including(
              remote_id: transaction.id,
              buyer_id: transaction.buyer_id,
              amount: transaction.amount,
              state: TRX_STATE_TO_BL_STATE_MAP[transaction.state]
            )
          )

          expect(::Observer).to receive(:distribution).with(
            ::Observer::Metric::GMV,
            a_kind_of(Numeric),
            hash_including(:product, :state, :partner, :transaction_type)
          )

          expect(::Observer).to receive(:distribution).with(
            ::Observer::Metric::REVENUE,
            a_kind_of(Numeric),
            hash_including(:product, :partner, :transaction_type)
          )

          object.run!

          expect(transaction.succeeded?).to eq true
          expect(transaction.revenue).to be > 0
          expect(transaction.revenue).to eq scenario_detail[:expected_revenue]
          expect(transaction.revenue_at).not_to be_nil
        end
      end
    end

    context 'when trx doesn\'t have revenue column' do
      let(:transaction) { build(:postpaid_transaction_with_bill, :partner_succeeded) }

      it 'updates transaction state and doesn\'t raise error' do
        object = Escrow::UpdateTransactionStatus.new(transaction)
        expect(Escrow::Connection).to receive(:patch).with(
          any_args,
          hash_including(
            remote_id: transaction.id,
            buyer_id: transaction.buyer_id,
            amount: transaction.amount,
            state: TRX_STATE_TO_BL_STATE_MAP[transaction.state]
          )
        )

        expect(::Observer).to receive(:distribution).with(
          ::Observer::Metric::GMV,
          a_kind_of(Numeric),
          hash_including(:product, :state, :partner, :transaction_type)
        )

        expect(::Observer).not_to receive(:distribution).with(
          ::Observer::Metric::REVENUE,
          a_kind_of(Numeric),
          hash_including(:product, :partner, :transaction_type)
        )

        expect(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(
          action: 'refund_rate',
          status: :success
        ).and_return(double(run!: :noop))

        expect { object.run! }.not_to raise_error
      end
    end

    context 'O2OVPE-845: when pdam transaction partner failed' do
      let(:transaction) { create(:pdam_transaction_with_bill, :partner_failed) }

      it 'record failed autoswitch value' do
        expect(Action::PdamAutoswitch::Mechanism::Record).to receive(:new).with(
          operator_id: transaction.operator.id,
          action: 'refund_rate',
          status: :failed
        ).and_return(double(run!: :noop))

        object = Escrow::UpdateTransactionStatus.new(transaction)
        expect(Observer).to receive(:histogram).with(
          Observer::Metric::SQL_LATENCY,
          anything,
          anything
        ).at_least(:once)

        expect(Escrow::Connection).to receive(:patch).with(
          any_args,
          hash_including(
            remote_id: transaction.id,
            buyer_id: transaction.buyer_id,
            amount: transaction.amount,
            state: TRX_STATE_TO_BL_STATE_MAP[transaction.state]
          )
        )

        expect(::Observer).to receive(:distribution).with(
          ::Observer::Metric::GMV,
          a_kind_of(Numeric),
          hash_including(:product, :state, :partner, :transaction_type)
        )

        object.run!

        expect(transaction.succeeded?).to eq false
        expect(transaction.revenue).to be 0
        expect(transaction.revenue_at).to be_nil
      end
    end

    context 'O2OVPE-1674: when electricity transaction partner failed' do
      let(:transaction) { create(:postpaid_transaction_with_bill, :partner_failed) }

      it 'record failed autoswitch value' do
        expect(Action::ElectricityAutoswitch::Mechanism::Record).to receive(:new).with(
          action: 'refund_rate',
          status: :failed
        ).and_return(double(run!: :noop))

        object = Escrow::UpdateTransactionStatus.new(transaction)
        expect(Observer).to receive(:histogram).with(
          Observer::Metric::SQL_LATENCY,
          anything,
          anything
        ).at_least(:once)

        expect(Escrow::Connection).to receive(:patch).with(
          any_args,
          hash_including(
            remote_id: transaction.id,
            buyer_id: transaction.buyer_id,
            amount: transaction.amount,
            state: TRX_STATE_TO_BL_STATE_MAP[transaction.state]
          )
        )

        expect(::Observer).to receive(:distribution).with(
          ::Observer::Metric::GMV,
          a_kind_of(Numeric),
          hash_including(:product, :state, :partner, :transaction_type)
        )

        object.run!

        expect(transaction.state).to eq('failed')
      end
    end
  end
end
