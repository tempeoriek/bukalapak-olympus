require 'rails_helper'

RSpec.describe Form::Recurrence::Base, type: :model do
  let(:params) {
    {
      recurrence_value: 1,
      recurrence_type: 'on_date'
    }
  }
  subject { Form::Recurrence::Base.new(params, 1, 300000) }

  it { expect(subject).to respond_to(:recurrence_value) }
  it { expect(subject).to respond_to(:recurrence_type) }
  it { expect(subject).to respond_to(:action_date) }
  it { expect(subject).to respond_to(:buyer_id) }
  it { expect(subject).to respond_to(:amount) }
end
