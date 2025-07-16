require "rails_helper"

RSpec.describe Form::BpjsKesehatanPartner, type: :form do
  let(:params) {
    {
      name: "sepulsa",
      partner_admin_charge: 2000,
      bukalapak_admin_charge: 3000,
      active: true
    }
  }

  let(:update_params) {
    {
      name: "sepulsa",
      partner_admin_charge: 2000,
      bukalapak_admin_charge: 3000,
      active: true
    }
  }

  describe '#update_params' do
    subject { described_class.new params }

    it { expect(subject.update_params).to eq(update_params) }
  end
end
