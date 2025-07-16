require "rails_helper"
RSpec.describe PdamRecurrenceTemplateDetail, type: :model do
  let(:operator) { build_stubbed(:pdam_operator) }
  let(:transaction) { build_stubbed(:pdam_recurrence_template_detail) }
  let(:expected_json_response) {
    {
      id: 1,
      customer_number: '12345',
      customer_name: 'BADRUN',
      operator_id: 1,
      buyer_id: 1,
      recursive_id: 1,
      operator: {
        id: 1,
        name: "Denpasar",
        group: "Bali",
        image_url: "http://i0.kym-cdn.com/entries/icons/mobile/000/013/564/doge.jpg"
      }
    }.as_json
  }
  describe 'as_json' do
    it { expect(transaction.as_json).to eq (expected_json_response) }
  end
end