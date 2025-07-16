require 'rails_helper'

RSpec.describe Recurrence::BpjsKesehatan::Create, type: :model do

  let(:partner_sepulsa) { build_stubbed(:bpjs_kesehatan_partner) }
  let(:recursive_response) {
    {
      data: {
        id: 1
      },
      http_status: 201
    }.to_json
  }

  let(:request_params) {
    {
      recurrence_value: '1',
      recurrence_type: 'on_date',
      customer_number: '3576023312213',
      phone_number: '082160505050'
    }
  }
  let(:response) {
    result = ResponseGeneralizer::BpjsKesehatan.new
    result.customer_name = 'SEPULSAWATI'
    result.family_member_count = 2
    result
  }

  let(:form) {
    Form::Recurrence::BpjsKesehatan.new(request_params, response, 1, 300000)
  }

  before do
    allow(BpjsKesehatanPartner).to receive(:find_by).with(state: 'active').and_return(partner_sepulsa)
    allow(Channel::Connection::Http).to receive(:post).and_return recursive_response
    allow_any_instance_of(Recurrence::BpjsKesehatan::Notifier).to receive(:run!).and_return true
  end

  describe 'run!' do
    context 'when not error' do
      subject { Recurrence::BpjsKesehatan::Create.new(form) }
      it 'runs correctly' do
        expect_any_instance_of(Recurrence::BpjsKesehatan::Create).to receive(:template_detail_klass_instance).and_return BpjsKesehatanRecurrenceTemplateDetail.new
        expect_any_instance_of(Recurrence::BpjsKesehatan::Create).to receive(:postpaid_product).at_least(:once).and_return 'bpjs-kesehatan'
        expect_any_instance_of(Recurrence::BpjsKesehatan::Create).to receive(:set_template_detail).and_return true
        expect_any_instance_of(Recurrence::BpjsKesehatan::Create).to receive(:generate_log_message).and_return true
        expect { subject.run! }.not_to raise_error
      end
    end

    context 'when error' do
      subject { Recurrence::BpjsKesehatan::Create.new(form) }
      it 'reraise error' do
        allow_any_instance_of(Recurrence::BpjsKesehatan::Create).to receive(:template_detail_klass_instance).and_return BpjsKesehatanRecurrenceTemplateDetail.new
        allow_any_instance_of(Recurrence::BpjsKesehatan::Create).to receive(:set_template_detail).and_raise(::Exceptions::DefaultError.new)
        expect_any_instance_of(Recurrence::BpjsKesehatan::Create).to receive(:postpaid_product).at_least(:once).and_return 'bpjs-kesehatan'
        expect_any_instance_of(Recurrence::BpjsKesehatan::Create).to receive(:generate_error_log_message).and_return true
        expect { subject.run! }.to raise_error(::Exceptions::DefaultError)
      end
    end
  end

end
