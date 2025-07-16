require 'rails_helper'

::Toggles.constants.select do |klass|
  RSpec.describe ::Toggles.const_get(klass), type: :model do
    describe '.description' do
      it { expect(described_class.description).not_to be_empty }
    end
  end
end
