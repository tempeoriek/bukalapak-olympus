require "rails_helper"

RSpec.describe Action::CreditCardBillPartner::Update, type: :model do

  let(:cc_biller) { create(:credit_card_biller, :partner_pnl, :bni) }

  let(:cc_biller_partner_other) {
    create(:credit_card_bill_partner, :bni, credit_card_biller: cc_biller)
  }

  let(:request_params_base) {
    {
      "id" => cc_biller.partner.id,
      "biller_id" => cc_biller.id,
      "name" => "bni",
      "terms_and_conditions" => "Bayar On-Time Yak!",
      "biller_code" => 'BNI',
      "bukalapak_admin_charge" => 1000,
      "partner_admin_charge" => 2000,
      "active" => true,
      "revenue" => 1000,
    }.with_indifferent_access
  }

  let(:form_params) {
    Form::CreditCardBillPartner.new(request_params).update_params
  }

  describe '#run!' do
    before {
      allow(::CreditCardBiller).to receive(:find_by_id).with(cc_biller.id).and_return cc_biller
    }

    let(:request_params) { request_params_base }

    subject { described_class.new(form_params, cc_biller.partner) }

    it 'saves params correctly' do
      biller_partner = subject.run!

      expect(biller_partner.name).to                   eq request_params["name"]
      expect(biller_partner.terms_and_conditions).to   eq request_params["terms_and_conditions"]
      expect(biller_partner.biller_code).to            eq request_params["biller_code"]
      expect(biller_partner.bukalapak_admin_charge).to eq request_params["bukalapak_admin_charge"]
      expect(biller_partner.partner_admin_charge).to   eq request_params["partner_admin_charge"]
      expect(biller_partner.state).to                  eq 'active'
      expect(biller_partner.revenue).to                eq request_params["revenue"]
    end

    context 'when active is true' do
      let(:request_params) { request_params_base.merge({
        "active" => true,
      })}

      context 'when biller has only one partner' do
        it 'saves params correctly' do
          biller_partner = subject.run!
          expect(biller_partner.state).to eq 'active'
        end
      end

      context 'when updating diffirent partner' do
        it 'saves params correctly' do
          biller_partner = described_class.new(form_params, cc_biller_partner_other).run!
          expect(biller_partner.state).to eq 'active'
        end
      end
    end

    context 'when active is false' do
      let(:request_params) { request_params_base.merge({
        "active" => false,
      })}

      context 'when biller has only one partner' do
        it {
          expect { subject.run! }.to raise_error(Exceptions::AtLeastOnePartnerActive)
        }
      end

      context 'when updating diffirent partner' do
        it 'saves params correctly' do
          biller_partner = described_class.new(form_params, cc_biller_partner_other).run!
          expect(biller_partner.state).to eq 'inactive'
        end
      end
    end

  end
end
