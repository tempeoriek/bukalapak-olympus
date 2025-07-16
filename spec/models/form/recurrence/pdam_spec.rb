require 'rails_helper'

RSpec.describe Form::Recurrence::Pdam, type: :model do
  let(:params) {
    {
      recurrence_value: 1,
      recurrence_type: 'on_date',
      customer_number: '3576023312213'
    }
  }

  let(:object) {
    build_stubbed(:pdam_transaction_with_bill)
  }
  subject { Form::Recurrence::Pdam.new(params, object, 1, 300000) }

  it { expect(subject).to respond_to(:recurrence_value) }
  it { expect(subject).to respond_to(:recurrence_type) }
  it { expect(subject).to respond_to(:action_date) }
  it { expect(subject).to respond_to(:buyer_id) }
  it { expect(subject).to respond_to(:amount) }
  it { expect(subject).to respond_to(:customer_number) }
  it { expect(subject).to respond_to(:customer_name) }
  it { expect(subject).to respond_to(:operator_id) }
end
