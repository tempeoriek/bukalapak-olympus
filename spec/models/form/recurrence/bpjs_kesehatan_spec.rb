require 'rails_helper'

RSpec.describe Form::Recurrence::BpjsKesehatan, type: :model do
  let(:params) {
    {
      recurrence_value: 1,
      recurrence_type: 'on_date',
      customer_number: '3576023312213'
    }
  }
  let(:response) {
    result = ResponseGeneralizer::BpjsKesehatan.new
    result.customer_name = 'SEPULSAWATI'
    result.family_member_count = 2
    result
  }
  subject { described_class.new(params, response, 1, 300000) }

  it { expect(subject).to respond_to(:recurrence_value) }
  it { expect(subject).to respond_to(:recurrence_type) }
  it { expect(subject).to respond_to(:action_date) }
  it { expect(subject).to respond_to(:buyer_id) }
  it { expect(subject).to respond_to(:amount) }
  it { expect(subject).to respond_to(:customer_number) }
  it { expect(subject).to respond_to(:customer_name) }
  it { expect(subject).to respond_to(:phone_number) }
  it { expect(subject).to respond_to(:family_member_count) }
end
