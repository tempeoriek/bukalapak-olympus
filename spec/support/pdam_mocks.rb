RSpec.shared_context 'pdam_mocks', shared_context: :metadata do
  include Postpaid::Constant

  let(:pdam_transaction) { build(:pdam_transaction_with_bill, :processed) }
  let(:success_response) do
    ResponseGeneralizer::Pdam.new do |r|
      r.status = SUCCESS
      r.partner_transaction_id = 1
      r.address = 'Jakarta'
      r.bills = pdam_transaction.pdam_bills
      r.details = { sub_segment: 'GOL 3A', biller_ref: '00000001' }
    end
  end
  let(:failed_response) do
    ResponseGeneralizer::Pdam.new do |r|
      r.status = FAILED
    end
  end
  let(:pending_response) do
    ResponseGeneralizer::Pdam.new do |r|
      r.status = PENDING
    end
  end
end
