require 'rails_helper'

RSpec.describe ResponseGeneralizer::Pdam, type: :model do
  subject { ResponseGeneralizer::Pdam.new }

  describe '.operator' do
    it { expect(subject).to respond_to(:operator) }
  end

  describe '.admin_charge' do
    it { expect(subject).to respond_to(:admin_charge) }
  end
end
