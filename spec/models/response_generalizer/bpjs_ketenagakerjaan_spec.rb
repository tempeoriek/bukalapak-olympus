require 'rails_helper'

RSpec.describe ResponseGeneralizer::BpjsKetenagakerjaan, type: :model do
  subject { ResponseGeneralizer::BpjsKetenagakerjaan.new }
  describe '.admin_charge' do
    it { expect(subject).to respond_to(:admin_charge) }
  end
end
