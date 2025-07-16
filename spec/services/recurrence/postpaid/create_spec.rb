require 'rails_helper'

RSpec.describe Recurrence::Postpaid::Create, type: :model do
  let(:recursive_response) {
    {
      data: {
        id: 1
      },
      http_status: 201
    }.to_json
  }

  let(:request_params_beginning_of_month) {
    {
      recurrence_value: '1',
      recurrence_type: 'on_date'
    }
  }

  let(:request_params_end_of_month) {
    {
      recurrence_value: Time.now.end_of_month.day.to_s,
      recurrence_type: 'on_date'
    }
  }

  let(:form_beginning_of_month) {
    Form::Recurrence::Base.new(request_params_beginning_of_month, 1, 300000)
  }

  let(:form_end_of_month) {
    Form::Recurrence::Base.new(request_params_end_of_month, 1, 300000)
  }

  describe 'run!' do
    context 'when beginning of month' do
      subject { Recurrence::Postpaid::Create.new(form_beginning_of_month) }
      it 'runs correctly' do
        expect_any_instance_of(Recurrence::Postpaid::Create).to receive(:template_detail_klass_instance).and_return ElectricityPostpaidRecurrenceTemplateDetail.new
        expect_any_instance_of(Recurrence::Postpaid::Create).to receive(:postpaid_product).at_least(:once).and_return 'electricity_postpaid'
        expect_any_instance_of(Recurrence::Postpaid::Create).to receive(:set_template_detail).and_return true
        expect_any_instance_of(Recurrence::Postpaid::Create).to receive(:generate_log_message).and_return true
        expect_any_instance_of(Recurrence::Postpaid::Create).to receive(:notify_subscribe).and_return true
        expect(Channel::Connection::Http).to receive(:post).and_return recursive_response
        expect { subject.run! }.not_to raise_error
      end
    end

    context 'when end of month' do
      subject { Recurrence::Postpaid::Create.new(form_end_of_month) }
      it 'runs correctly' do
        expect_any_instance_of(Recurrence::Postpaid::Create).to receive(:template_detail_klass_instance).and_return ElectricityPostpaidRecurrenceTemplateDetail.new
        expect_any_instance_of(Recurrence::Postpaid::Create).to receive(:postpaid_product).at_least(:once).and_return 'electricity_postpaid'
        expect_any_instance_of(Recurrence::Postpaid::Create).to receive(:set_template_detail).and_return true
        expect_any_instance_of(Recurrence::Postpaid::Create).to receive(:generate_log_message).and_return true
        expect_any_instance_of(Recurrence::Postpaid::Create).to receive(:notify_subscribe).and_return true
        expect(Channel::Connection::Http).to receive(:post).and_return recursive_response
        expect { subject.run! }.not_to raise_error
      end
    end

    context 'when error' do
      subject { Recurrence::Postpaid::Create.new(form_beginning_of_month) }
      it 'reraise error' do
        allow_any_instance_of(Recurrence::Postpaid::Create).to receive(:template_detail_klass_instance).and_return ElectricityPostpaidRecurrenceTemplateDetail.new
        allow_any_instance_of(Recurrence::Postpaid::Create).to receive(:set_template_detail).and_raise(::Exceptions::DefaultError.new)
        expect_any_instance_of(Recurrence::Postpaid::Create).to receive(:postpaid_product).at_least(:once).and_return 'electricity_postpaid'
        expect_any_instance_of(Recurrence::Postpaid::Create).to receive(:generate_error_log_message).and_return true
        expect { subject.run! }.to raise_error(::Exceptions::DefaultError)
      end
    end
  end

end
