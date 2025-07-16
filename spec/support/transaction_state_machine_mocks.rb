RSpec.shared_context 'transaction_state_machine_mocks', :shared_context => :metadata do
  include Postpaid::Constant

  describe '#call gmv metric' do
    let(:metric_payload) {
      {
        product: transaction.product_type,
        state: next_state,
        partner: transaction.partner_name,
        transaction_type: transaction.transaction_type,
        biller_product: transaction.biller_product
      }
    }

    before(:each) do
      expect(Observer).to receive(:histogram).with(Observer::Metric::SQL_LATENCY, anything, anything).at_least(:once)     
      expect(Observer).to receive(:counter).with(Observer::Metric::STATE, 1, metric_payload).and_return(true)
      expect(Observer).to receive(:distribution).with(Observer::Metric::GMV, transaction.amount, metric_payload).and_return(true)
    end

    context 'when transaction paid' do
      let(:next_state) { :paid }
      let(:transaction) { build(:postpaid_transaction_with_bill) }
      it 'run successfully' do
        expect{ transaction.pay! }.not_to raise_error
        expect(transaction.state).to eq('paid')
      end
    end

    context 'when transaction succeeded' do
      let(:next_state) { :succeeded }
      let(:transaction) { build(:postpaid_transaction_with_bill, :partner_succeeded) }
      it 'run successfully' do
        expect(Observer).to receive(:histogram).with(Observer::Metric::TIME_TO_SUCCEED, anything, anything).and_return(true)
        expect{ transaction.success! }.not_to raise_error
        expect(transaction.state).to eq('succeeded')
      end
    end

    context 'when transaction failed' do
      let(:next_state) { :failed }
      let(:transaction) { build(:postpaid_transaction_with_bill, :partner_failed) }
      it 'run successfully' do
        expect{ transaction.fail! }.not_to raise_error
        expect(transaction.state).to eq('failed')
      end
    end
  end

  describe '#not calling gmv metric' do
    let(:metric_payload) {
      {
        product: transaction.product_type,
        state: next_state,
        partner: transaction.partner_name,
        transaction_type: transaction.transaction_type,
        biller_product: transaction.biller_product
      }
    }
    before(:each) do
      expect(Observer).to receive(:counter).with(Observer::Metric::STATE, 1, metric_payload).and_return(true)
      expect(Observer).not_to receive(:distribution).with(Observer::Metric::GMV, anything)
    end

    context 'when transaction failed' do
      let(:next_state) { :processed }
      let(:transaction) { build(:postpaid_transaction_with_bill, :paid) }
      it 'run successfully' do
        expect{ transaction.process! }.not_to raise_error
        expect(transaction.state).to eq('processed')
      end
    end
  end
end
