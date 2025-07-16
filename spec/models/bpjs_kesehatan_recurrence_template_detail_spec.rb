require "rails_helper"

RSpec.describe ElectricityPostpaidRecurrenceTemplateDetail, type: :model do
  let(:transaction) { build_stubbed(:bpjs_kesehatan_recurrence_template_detail) }

  let(:expected_json_response) {
    {
      id: transaction.id,
      customer_number: '0000001430071801',
      customer_name: 'SEPULSAWATI',
      buyer_id: 1,
      recursive_id: 1,
      family_member_count: 2,
      image_url: "https://s4.bukalapak.com/images/virtual_product/logo_bpjs.png"
    }.as_json
  }

  describe 'as_json' do
    it { expect(transaction.as_json).to eq (expected_json_response) }
  end
end
