require "rails_helper"

RSpec.describe Action::PhoneCreditTransaction::Create, type: :model do
  let(:customer_number) { '081234000001' }
  let(:provider) { build_stubbed :phone_credit_provider }
  let(:provider_prefix) { build_stubbed :provider_prefix }
  let(:form) { Form::PhoneCredit.new(customer_number) }
  subject { Action::PhoneCreditTransaction::Create.new(form, 1, 0) }

  let(:failed_partner_response) {
    r = ResponseGeneralizer::PhoneCreditPostpaid.new

    r.customer_number = '081234000001'
    r.bill_period = ['2018-01-01']
    r
  }

  before do
    allow(ProviderPrefix).to receive(:find_by).with(prefix: customer_number[0..4]).and_return(nil)
    allow(ProviderPrefix).to receive(:find_by).with(prefix: customer_number[0..3]).and_return(provider_prefix)
    allow(PhoneCreditProvider).to receive(:find).and_return(provider)
  end

  let(:success_partner_response) {
    r = ResponseGeneralizer::PhoneCreditPostpaid.new
    r.customer_number = '081234000001'
    r.customer_name = 'INDAH PRAWITA HAPSARI'
    r.reference_no = '2203267'
    r.bill_count = 1
    r.bill_period = [ '2018-01-01' ]
    r.bill_amount = 25000
    r.partner_admin_charge = 1000
    r.bukalapak_admin_charge = 500
    r.admin_charge = 1500
    r.total_amount = 26500
    r.provider_id = '1'
    r.provider_name = provider.provider
    r.provider_product_name = provider.product_name
    r.provider_logo_url = provider.logo_url
    r.partner = 'sepulsa'

    r
  }


  describe '.run!' do
    context 'when inquiry successful' do
      it 'could create transaction' do
        allow(subject).to receive(:get_inquiry).and_return(success_partner_response)
        expect_any_instance_of(Escrow::RegisterTransaction).to receive(:run!).and_return({
          id: 1
        })

        expect { subject.run! }.not_to raise_error
      end
    end

    context 'when inquiry unsuccessful' do
      it 'raise error' do
        allow(subject).to receive(:get_inquiry).and_return(failed_partner_response)

        expect { subject.run! }.to raise_error(Exceptions::CreateTransactionError)
      end
    end
  end
end
