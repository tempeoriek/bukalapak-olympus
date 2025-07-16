require 'rails_helper'
include Postpaid::Constant

RSpec.describe BpjsKesehatanPartner, type: :model do
  subject { build_stubbed(:bpjs_kesehatan_family_member) }

  let(:expected_json_response) {
    {
      'id' => subject.id,
      'member_number' => '123814123',
      'name' => 'Prengki',
      'premium' => 55000,
      'balance' => 0
    }
  }

  describe '.as_json' do
    it { expect(subject.as_json).to eq (expected_json_response) }
  end
end
