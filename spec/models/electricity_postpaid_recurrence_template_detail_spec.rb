require "rails_helper"

RSpec.describe ElectricityPostpaidRecurrenceTemplateDetail, type: :model do
  let(:transaction) { build_stubbed(:electricity_postpaid_recurrence_template_detail) }

  let(:expected_json_response) {
    {
      id: 1,
      customer_number: '12345',
      customer_name: 'BADRUN',
      power: 900,
      segmentation: 'R1',
      buyer_id: 1,
      recursive_id: 1,
      image_url: "https://s4.bukalapak.com/images/virtual_product/logo_pln.png"
    }.as_json
  }

  describe 'as_json' do
    it { expect(transaction.as_json).to eq (expected_json_response) }
  end
end
