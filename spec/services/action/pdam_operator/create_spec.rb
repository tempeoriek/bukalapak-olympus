require "rails_helper"

RSpec.describe Action::PdamOperator::Create, type: :model do

  let(:params) {
    create(:pdam_operator).attributes.except("id").with_indifferent_access
  }

  subject { described_class.new(params) }

  describe '#run!' do
    it 'saves params correctly' do
      operator = subject.run!
      expect(operator.attributes.except("id")).to match(params)
    end
  end
end
