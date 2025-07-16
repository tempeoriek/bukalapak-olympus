# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Channel, type: :model do
  describe '.new_partner_channel' do
    context 'when product is electricity postpaid' do
      partner_mappers = {
        'sepulsa'                => Channel::Sepulsa::ElectricityPostpaid,
        'bukopin'                => Channel::Bukopin::ElectricityPostpaid,
        'ayoconnect'             => Channel::Ayoconnect::ElectricityPostpaid,
        'tektaya'                => Channel::Tektaya::ElectricityPostpaid,
        'sepulsa_bukaconnect'    => Channel::Sepulsa::ElectricityPostpaid,
        'bukopin_bukaconnect'    => Channel::Bukopin::ElectricityPostpaid,
        'ayoconnect_bukaconnect' => Channel::Ayoconnect::ElectricityPostpaid,
        'tektaya_bukaconnect'    => Channel::Tektaya::ElectricityPostpaid,
        'vsi_thor'               => Channel::Thor::ElectricityPostpaid,
        'sat_thor'               => Channel::Thor::ElectricityPostpaid
      }

      partner_mappers.keys.each do |partner|
        context "when chosen partner is #{partner}" do
          let(:form) { Form::ElectricityPostpaid.new('123456789012', 'some_username', partner) }
          let(:partner_object) { build_stubbed(:electricity_postpaid_partner, partner.to_sym) }

          before do
            allow(ElectricityPostpaidPartner).to receive(:find_by).and_return(partner_object)
          end

          it 'returns the correct partner klass' do
            partner_klass = partner_mappers[partner]
            expect(described_class.new_partner_channel(form)).to be_a partner_klass
          end
        end
      end

      context 'when product is cc bill' do
        # Old toggle still use persistent keystore
        before do
          allow(Toggles::WhitelistBni).to receive(:active?).and_return(false)
          allow(Toggles::WhitelistVisa).to receive(:active?).and_return(false)
        end

        context 'when partner is BNI' do
          let(:biller_id) { 1 }
          let(:form) { Form::CreditCardBill.new('4111111111111111', biller_id, 123_000) }

          let(:biller) { create(:credit_card_biller, :bni, :partner_bni) }

          before do
            allow(CreditCardBiller).to receive(:find).with(biller_id).and_return(biller)
          end

          context 'when the user is whitelisted' do
            let(:form) { Form::CreditCardBill.new('4111111111111111', biller_id, 123_000, buyer_id: 1) }

            before do
              allow(WhitelistNewBniUserIds).to receive(:include?).with(form.buyer_id.to_s).and_return(true)
            end

            it 'returns the new BNI channel' do
              expect(::Toggle::CreditCardBill::WhitelistNewBNI).to receive(:active?).and_return(true)
              expect(described_class.new_partner_channel(form)).to be_a Channel::NewBNI::CreditCardBill
            end
          end

          context 'when toggle for new BNI is on' do
            it 'returns the new BNI channel' do
              expect(::Toggle::CreditCardBill::NewBNI).to receive(:active?).and_return(true)
              expect(::Toggle::CreditCardBill::WhitelistNewBNI).to receive(:active?).and_return(false)
              expect(described_class.new_partner_channel(form)).to be_a Channel::NewBNI::CreditCardBill
            end
          end

          context 'when toggle for new BNI is off' do
            it 'returns the old BNI channel' do
              expect(::Toggle::CreditCardBill::NewBNI).to receive(:active?).and_return(false)
              expect(::Toggle::CreditCardBill::WhitelistNewBNI).to receive(:active?).and_return(false)
              expect(described_class.new_partner_channel(form)).to be_a Channel::BNI::CreditCardBill
            end
          end
        end

        context 'when partner is PNL' do
          let(:biller_id) { 1 }
          let(:form) { Form::CreditCardBill.new('4111111111111111', biller_id, 123_000) }

          let(:biller) { create(:credit_card_biller, :non_bni, :partner_pnl) }

          before do
            allow(CreditCardBiller).to receive(:find).with(biller_id).and_return(biller)
          end

          it 'returns the PNL channel' do
            expect(described_class.new_partner_channel(form)).to be_a Channel::Pnl::CreditCardBill
          end
        end

        context 'when partner is Visa' do
          let(:biller_id) { 1 }
          let(:form) { Form::CreditCardBill.new('4111111111111111', biller_id, 123_000) }

          let(:biller) { create(:credit_card_biller, :visa, :partner_visa) }

          before do
            allow(CreditCardBiller).to receive(:find).with(biller_id).and_return(biller)
          end

          it 'returns the Visa channel' do
            expect(described_class.new_partner_channel(form)).to be_a Channel::Visa::CreditCardBill
          end
        end

        context 'when partner is cimbniaga_thor' do
          let(:biller_id) { 1 }
          let(:form) { Form::CreditCardBill.new('4111111111111111', biller_id, 100_000) }

          let(:biller) { create(:credit_card_biller, :cimbniaga_thor, :partner_cimbniaga_thor) }

          before do
            allow(CreditCardBiller).to receive(:find).with(biller_id).and_return(biller)
          end

          it 'returns the Thor channel' do
            expect(described_class.new_partner_channel(form)).to be_a Channel::Thor::CreditCardBill
          end
        end
      end

      context 'when partner channel is not exist' do
        let(:partner) { 'some_partner' }
        let(:form) { Form::ElectricityPostpaid.new('123456789012', 'some_username', partner) }
        let(:partner_object) { build_stubbed(:electricity_postpaid_partner, name: 'some_partner') }

        before do
          allow(ElectricityPostpaidPartner).to receive(:find_by).and_return(partner_object)
        end

        it 'raise errors' do
          expect { described_class.new_partner_channel(form) }.to raise_error(::Exceptions::PartnerClassNotFound)
        end
      end
    end

    context 'when product is pdam' do
      partner_mappers = {
        'sepulsa' => Channel::Sepulsa::Pdam,
        'dji' => Channel::Dji::Pdam,
        'vsi_thor' => Channel::Thor::Pdam,
        'mkm_thor' => Channel::Thor::Pdam,
        'fortuna_thor' => Channel::Thor::Pdam,
        'bms_thor' => Channel::Thor::Pdam,
      }

      partner_mappers.keys.each_with_index do |partner, i|
        context "when choosen partner is #{partner}" do
          let(:form) { Form::Pdam.new('199890000000', 'some-product-code', 'some_username', partner) }
          let(:partner_object) { build_stubbed(:pdam_operator, partner: partner.to_sym) } # partner is enumeration

          before do
            allow(PdamOperator).to receive(:find_by_id).and_return(partner_object)
          end

          it 'returns the correct partner klass' do
            partner_klass = partner_mappers[partner]
            expect(described_class.new_partner_channel(form)).to be_a partner_klass
          end
        end
      end
    end
  end
end
