FactoryBot.define do
  factory :credit_card_bill_partner, class: CreditCardBillPartner do
    trait :bni do
      name 'bni'
      partner_admin_charge 0
      bukalapak_admin_charge 0
      state 'active'
      terms_and_conditions '<p>1. Proses verifikasi pembayaran maks. 3x24 jam di hari kerja.</p><p>2. Periksa kembali Bank Penyedia dan Nomor Kartu Kredit yang kamu masukkan. Bukalapak <b><u>tidak bertanggung jawab</b></u> jika ada kesalahan dari pengguna seperti salah memasukkan no. kartu kredit.</p><p>3. Pastikan kamu sudah mengetahui jumlah tagihan dan min. pembayaran untuk tagihan kartu kreditmu.</p><p>4. Tidak ada biaya admin untuk BNI.</p>'
      revenue 1000
    end

    trait :pnl do
      name 'pnl'
      partner_admin_charge 5000
      bukalapak_admin_charge 0
      state 'active'
      terms_and_conditions '<p>1. Proses verifikasi pembayaran maks. 3x24 jam di hari kerja.</p><p>2. Periksa kembali Bank Penyedia dan Nomor Kartu Kredit yang kamu masukkan. Bukalapak <b><u>tidak bertanggung jawab</b></u> jika ada kesalahan dari pengguna seperti salah memasukkan no. kartu kredit.</p><p>3. Pastikan kamu sudah mengetahui jumlah tagihan dan min. pembayaran untuk tagihan kartu kreditmu.</p><p>4. Tidak ada biaya admin untuk BNI.</p>'
      revenue 1000
    end

    trait :visa do
      name 'visa'
      partner_admin_charge 1000
      bukalapak_admin_charge 0
      state 'active'
      terms_and_conditions '<p>1. Proses verifikasi pembayaran maks. 3x24 jam di hari kerja.</p><p>2. Periksa kembali Bank Penyedia dan Nomor Kartu Kredit yang kamu masukkan. Bukalapak <b><u>tidak bertanggung jawab</b></u> jika ada kesalahan dari pengguna seperti salah memasukkan no. kartu kredit.</p><p>3. Pastikan kamu sudah mengetahui jumlah tagihan dan min. pembayaran untuk tagihan kartu kreditmu.</p><p>4. Tidak ada biaya admin untuk BNI.</p>'
      revenue 1000
    end

    trait :thor do
      name 'thor'
      partner_admin_charge 1000
      bukalapak_admin_charge 0
      state 'active'
      terms_and_conditions '<p>1. Proses verifikasi pembayaran maks. 3x24 jam di hari kerja.</p><p>2. Periksa kembali Bank Penyedia dan Nomor Kartu Kredit yang kamu masukkan. Bukalapak <b><u>tidak bertanggung jawab</b></u> jika ada kesalahan dari pengguna seperti salah memasukkan no. kartu kredit.</p><p>3. Pastikan kamu sudah mengetahui jumlah tagihan dan min. pembayaran untuk tagihan kartu kreditmu.</p><p>4. Tidak ada biaya admin untuk BNI.</p>'
      revenue 1000
    end

    trait :cimbniaga_thor do
      name 'cimbniaga_thor'
      partner_admin_charge 1000
      bukalapak_admin_charge 0
      state 'active'
      terms_and_conditions '<p>1. Proses verifikasi pembayaran maks. 3x24 jam di hari kerja.</p><p>2. Periksa kembali Bank Penyedia dan Nomor Kartu Kredit yang kamu masukkan. Bukalapak <b><u>tidak bertanggung jawab</b></u> jika ada kesalahan dari pengguna seperti salah memasukkan no. kartu kredit.</p><p>3. Pastikan kamu sudah mengetahui jumlah tagihan dan min. pembayaran untuk tagihan kartu kreditmu.</p><p>4. Tidak ada biaya admin untuk BNI.</p>'
      revenue 1000
    end
  end
end
