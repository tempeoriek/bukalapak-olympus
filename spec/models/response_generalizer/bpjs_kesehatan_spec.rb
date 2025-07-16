require 'rails_helper'

RSpec.describe ResponseGeneralizer::BpjsKesehatan, type: :model do
  subject { ResponseGeneralizer::BpjsKesehatan.new }
  describe '.admin_charge' do
    it { expect(subject).to respond_to(:admin_charge) }
  end
end
