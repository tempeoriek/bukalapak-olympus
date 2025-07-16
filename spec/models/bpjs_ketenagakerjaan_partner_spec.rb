require 'rails_helper'
include Postpaid::Constant

RSpec.describe BpjsKetenagakerjaanPartner, type: :model do
  subject { build_stubbed(:bpjs_ketenagakerjaan_partner) }

  describe '.admin_charge' do
    it { expect(subject.admin_charge).to eq (subject.bukalapak_admin_charge + subject.partner_admin_charge) }
  end
end
