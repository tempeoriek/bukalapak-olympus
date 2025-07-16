require 'rails_helper'

RSpec.describe Form::Recurrence::PhoneCreditPostpaid, type: :model do
  let(:params) {
    {
      recurrence_value:    1,
      recurrence_type:    'on_date',
      customer_number:    '3576023312213',
      payment_method:     'deposit',
      action_date:        '2020-02-20'
    }
  }

  let(:object) {
    ResponseGeneralizer::PhoneCreditPostpaid.new
  }

  subject { Form::Recurrence::PhoneCreditPostpaid.new(params, object, 1, 300000) }

  context 'when created successfully' do
    it { expect(subject).to respond_to(:recurrence_value) }
    it { expect(subject).to respond_to(:recurrence_type) }
    it { expect(subject).to respond_to(:action_date) }
    it { expect(subject).to respond_to(:buyer_id) }
    it { expect(subject).to respond_to(:amount) }
    it { expect(subject).to respond_to(:customer_number) }
    it { expect(subject).to respond_to(:customer_name) }

    it { expect(subject.recurrence_value).to  eq params[:recurrence_value] }
    it { expect(subject.recurrence_type).to   eq params[:recurrence_type] }
    it { expect(subject.customer_number).to   eq params[:customer_number] }
    it { expect(subject.payment_method).to    eq params[:payment_method] }
    it { expect(subject.action_date).to       eq params[:action_date] }
  end
end
