RSpec.shared_context 'bpjs_kesehatan_mocks', :shared_context => :metadata do
  include Postpaid::Constant

  let(:bpjs_transaction) { build(:bpjs_kesehatan_transaction, :processed) }
  let(:success_response) {
    ResponseGeneralizer::BpjsKesehatan.new do |r|
      r.status = SUCCESS
      r.partner_transaction_id = 1
      r.reference_number = 'ABC123'
      r.info = 'HUBUNGI KANTOR BPJS KESEHATAN TERDEKAT UNTUK INFO LEBIH LANJUT'
    end
  }
  let(:failed_response) {
    ResponseGeneralizer::BpjsKesehatan.new do |r|
      r.status = FAILED
    end
  }
  let(:pending_response) {
    ResponseGeneralizer::BpjsKesehatan.new do |r|
      r.status = PENDING
    end
  }
end