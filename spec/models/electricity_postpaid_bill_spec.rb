require "rails_helper"

RSpec.describe Bill, type: :model do
  let(:bills) { build(:bill) }
  

  describe 'validation' do
    it { expect(bills.save).to eq (true) }
  end
end
