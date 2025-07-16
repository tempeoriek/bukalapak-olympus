# ruby encoding: utf-8
include Postpaid::Constant

def populate_pdam_operators
  pdam_operators_file = File.read("#{Rails.root}/db/seeds/pdam_operators.json")
  pdam_operators = JSON.parse(pdam_operators_file)
  pdam_operators.each do | pdam_operator |
    next unless PdamOperator.find_by(code: pdam_operator['code']).nil? # smart seeder hehe
    pdam_operator['bukalapak_admin_charge'] = 1450
    pdam_operator['partner_admin_charge'] = 550
    pdam_operator['terms_and_conditions'] = "Kamu bisa bayar mulai tanggal 1 jam 12 siang sampai 2 hari kerja terakhir di akhir bulan."
    PdamOperator.create(pdam_operator)
  end
end

# electricity postpaid partner
ElectricityPostpaidPartner.create(name: 'sepulsa', bukalapak_admin_charge: 300, partner_admin_charge: 700, state: 0)
ElectricityPostpaidPartner.create(name: 'bukopin', bukalapak_admin_charge: 0, partner_admin_charge: 2750, state: 1)

# bpjs kesehatan partners
BpjsKesehatanPartner.create(name: 'sepulsa', bukalapak_admin_charge: 1000, partner_admin_charge: 500, state: 1)
BpjsKesehatanPartner.create(name: 'dji-bpjs', bukalapak_admin_charge: 1000, partner_admin_charge: 500, state: 0)

def populate_provider
  provider_file = File.read("#{Rails.root}/db/seeds/provider.json")
  providers = JSON.parse(provider_file)
  providers.each do |provider|
    ActiveRecord::Base.transaction do
      provider['bukalapak_admin_charge'] = PHONE_CREDIT_BUKALAPAK_CHARGE
      provider['active'] = 1
      record = PhoneCreditProvider.create!(provider.except("prefix"))
      puts "Provider #{record[:provider]} - #{record[:product_name]} berhasil ditambahkan"
      provider_id = record.id
      prefixs = provider["prefix"]
      prefixs.each do |prefix|
        ProviderPrefix.create!({prefix: prefix, provider_id: provider_id})
        puts "--- Prefix '#{prefix}' untuk produk #{record[:product_name]} berhasil ditambahkan"
      end
    end
  end
end

def populate_cc_biller_and_partner
  default_partner_values = {
    bni: {
      name: 'bni',
      terms_and_conditions: '<ol><li>Pastikan kamu sudah mengetahui jumlah tagihan dan min. pembayaran untuk tagihan kartu kreditmu.</li><li>Biaya admin akan ditambahkan pada tagihan di bulan berikutnya.</li></ol>',
      bukalapak_admin_charge: 2000,
      partner_admin_charge: 0,
      state: :active,
    },
    pnl: {
      name: 'pnl',
      terms_and_conditions: '<ol><li>Pastikan kamu sudah mengetahui jumlah tagihan dan min. pembayaran untuk tagihan kartu kreditmu.</li><li>Biaya admin akan ditambahkan pada tagihan di bulan berikutnya.</li></ol>',
      bukalapak_admin_charge: 1500,
      partner_admin_charge: 5000,
      state: :inactive,
    },
  }

  biller_file = File.read("#{Rails.root}/db/seeds/cc_billers.json")
  billers = JSON.parse(biller_file)
  billers.each do |biller|
    ActiveRecord::Base.transaction do
      biller['active'] = 1
      biller['image_url'] = "https://s2.bukalapak.com/images/desktop/aset-brand/section1-3.png"
      biller_record = CreditCardBiller.create!(biller.except('biller_partner_codes'))
      puts "Credit Card Biller #{biller_record[:name]} berhasil ditambahkan"

      biller['biller_partner_codes'].each do |partner, biller_partner_code|
        partner = CreditCardBillPartner.create!(default_partner_values[partner.to_sym].merge({
          biller_code: biller_partner_code,
          credit_card_biller_id: biller_record.id,
        }))
        puts "--- Credit Card Biller Partner #{partner[:name]} berhasil ditambahkan"
      end
    end
  end
end

populate_provider
populate_cc_biller_and_partner
populate_pdam_operators
