require "rails_helper"

RSpec.describe ElectricityPostpaidPartner, type: :model do
  let(:partner_sepulsa) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }
  let(:partner_bukopin) { build_stubbed(:electricity_postpaid_partner, :bukopin) }


  describe '#admin_charge' do
    it { expect(partner_sepulsa.admin_charge).to eq (partner_sepulsa.bukalapak_admin_charge + partner_sepulsa.partner_admin_charge) }
    it { expect(partner_bukopin.admin_charge).to eq (partner_bukopin.bukalapak_admin_charge + partner_bukopin.partner_admin_charge) }
  end

  describe '#is_bukaconnect_partner?' do
    context 'when partner is not bukaconnect' do
      let(:partner_object) { build_stubbed(:electricity_postpaid_partner, :sepulsa) }

      it 'returns false' do
        expect(partner_object.bukaconnect_partner?).to be false
      end
    end

    context 'when partner is bukaconnect' do
      let(:partner_object) { build(:electricity_postpaid_partner, :sepulsa_bukaconnect) }

      it 'returns true' do
        expect(partner_object.bukaconnect_partner?).to be true
      end
    end
  end
end
