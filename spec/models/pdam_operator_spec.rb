require "rails_helper"

RSpec.describe PdamOperator, type: :model do
  let(:operator) { build_stubbed(:pdam_operator) }
  let(:expected_as_json) {
    {
      'id' => operator.id,
      'name' => operator.name,
      'group' => operator.group,
      'image_url' => operator.image_url,
      'terms_and_conditions' => operator.terms_and_conditions,
      'have_issue' => operator.have_issue,
      'update_selling_price' => operator.update_selling_price
    }
  }
  let(:expected_admin_charge) { Test::ADMIN_CHARGE }

  describe '.as_json' do
    it { expect(operator.as_json).to eq (expected_as_json) }
  end

  describe '.admin_charge' do
    it { expect(operator.admin_charge).to eq expected_admin_charge }
  end
end
