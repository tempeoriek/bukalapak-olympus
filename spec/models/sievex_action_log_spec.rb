require "rails_helper"

RSpec.describe SievexActionLog, type: :model do
  let(:params) do
    {
      entity_id: 1,
      entity_type: 'credit_card_bill_transaction',
      actor: 'system',
      reason: 'Daily Limit Exceeded'
    }
  end

  subject { described_class.new(params) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      expect(subject).to be_valid
    end

    it 'is not valid without an entity_id' do
      subject.entity_id = nil
      expect(subject).not_to be_valid
    end

    it 'is not valid without an entity_type' do
      subject.entity_type = nil
      expect(subject).not_to be_valid
    end

    it 'is not valid without an actor' do
      subject.actor = nil
      expect(subject).not_to be_valid
    end

    it 'is not valid without a reason' do
      subject.reason = ''
      expect(subject).not_to be_valid
    end
  end
end
