require "rails_helper"

RSpec.describe Escrow::InvoiceDetail, type: :model do
  let(:invoice_id) { 123 }
  let(:expected_url) { "#{Channel::Config::BUKALAPAK_ENDPOINT}_internal/invoices/%s" % invoice_id }
  let(:response) { '{ "data": "marchell" }' }

  subject { described_class.get(invoice_id) }

  it 'calls the right url' do
    expect(Escrow::Connection).to receive(:get).with(expected_url).and_return response
    expect{ subject }.not_to raise_error
  end

  it 'returns the right data' do
    expect(Escrow::Connection).to receive(:get).with(expected_url).and_return response
    expect(subject).to eq("marchell")
  end
end
