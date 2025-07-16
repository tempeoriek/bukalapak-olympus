require "rails_helper"

RSpec.describe CreditCardBiller, type: :model do
  let(:biller) { create(:credit_card_biller, :bni, :partner_bni) }
  let(:expected_admin_charge) { 0 }
  let(:expected_as_json) {
    {
      'id' => biller.id,
      'name' => 'BNI',
      'image_url' => 'https://s2.bukalapak.com/images/desktop/aset-brand/section1-3.png',
      'terms_and_conditions' => '<p>1. Proses verifikasi pembayaran maks. 3x24 jam di hari kerja.</p><p>2. Periksa kembali Bank Penyedia dan Nomor Kartu Kredit yang kamu masukkan. Bukalapak <b><u>tidak bertanggung jawab</b></u> jika ada kesalahan dari pengguna seperti salah memasukkan no. kartu kredit.</p><p>3. Pastikan kamu sudah mengetahui jumlah tagihan dan min. pembayaran untuk tagihan kartu kreditmu.</p><p>4. Tidak ada biaya admin untuk BNI.</p>',
      'admin_charge' => biller.admin_charge
    }
  }

  describe 'validation' do
    it { expect(biller.valid?).to eq true }
  end

  describe '.admin_charge' do
    it { expect(biller.admin_charge).to eq (expected_admin_charge) }
  end

  describe '.partner' do
    it { expect(biller).to respond_to(:credit_card_bill_partner) }
    it { expect(biller.partner.name).to eq 'bni' }
  end

  describe '.as_json' do
    it { expect(biller.as_json).to eq (expected_as_json) }
  end

end
