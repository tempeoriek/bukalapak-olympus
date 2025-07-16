# frozen_string_literal: true
module MailerUtility
  include Postpaid::Constant

  STATE_MAPPER = {
    'succeeded' => 'succeeded',
    'partner_succeeded' => 'succeeded',
    'failed' => 'failed',
    'partner_failed' => 'failed'
  }

  SUBJECT_MAPPER = {
    'succeeded' => "Transaksi Berhasil Diproses untuk %s",
    'failed' => "Transaksi Tidak Berhasil untuk %s"
  }

  PRODUCT_NAME_MAPPER = {
    ELECTRICITY_PRODUCT => 'Tagihan Listrik Pascabayar',
    BPJS_KESEHATAN_PRODUCT => 'Tagihan BPJS Kesehatan',
    PDAM_PRODUCT => 'Tagihan Air PDAM',
    PHONE_CREDIT_PRODUCT => 'Tagihan Pulsa Pascabayar',
    CREDIT_CARD_BILL_PRODUCT => 'Tagihan Kartu Kredit',
    BPJS_KETENAGAKERJAAN_PRODUCT => 'Tagihan BPJS Ketenagakerjaan'
  }

  EMAIL_TAG_MAPPER = {
    ELECTRICITY_PRODUCT => {
      TRANSACTION_SUCCEEDED => 'virtual_product_postpaid_electricity_transaction_success',
      TRANSACTION_FAILED => 'virtual_product_postpaid_electricity_transaction_failed'
    },
    BPJS_KESEHATAN_PRODUCT => {
      TRANSACTION_SUCCEEDED => 'virtual_product_bpjs_kesehatan_transaction_success',
      TRANSACTION_FAILED => 'virtual_product_bpjs_kesehatan_transaction_failed'
    },
    PDAM_PRODUCT => {
      TRANSACTION_SUCCEEDED => 'virtual_product_pdam_transaction_success',
      TRANSACTION_FAILED => 'virtual_product_pdam_transaction_failed'
    },
    PHONE_CREDIT_PRODUCT => {
      TRANSACTION_SUCCEEDED => 'virtual_product_phone_credit_postpaid_transaction_success',
      TRANSACTION_FAILED => 'virtual_product_phone_credit_postpaid_transaction_failed'
    },
    CREDIT_CARD_BILL_PRODUCT => {
      TRANSACTION_SUCCEEDED => 'virtual_product_credit_card_bill_transaction_success',
      TRANSACTION_FAILED => 'virtual_product_credit_card_bill_transaction_failed'
    },
    BPJS_KETENAGAKERJAAN_PRODUCT => {
      TRANSACTION_SUCCEEDED => 'virtual_product_bpjs_ketenagakerjaan_transaction_success',
      TRANSACTION_FAILED => 'virtual_product_bpjs_ketenagakerjaan_transaction_failed'
    }
  }

  RECURRENCE_EMAIL_SUBJECT_MAPPER = {
    transaction_success: "Transaksi Rutin %s Berhasil Diproses",
    transaction_failed:  "Saldo BukaDompet Tidak Mencukupi",
    transaction_error:   "Transaksi Rutin Gagal: Pembayaran Tagihan %s Periode %s dengan Nomor Tagihan %s",
    subscribe_success:   "Pendaftaran Transaksi Rutin %s Berhasil",
    topup_deposit:       "Ayo Tambah Saldo BukaDompet Kamu",
    unsubscribe_success: "Transaksi Rutin %s Diberhentikan"
  }

  RECURRENCE_EMAIL_PRODUCT_NAME_MAPPER = {
    "bpjs_kesehatan": "BPJS Kesehatan",
    "electricity_postpaid": "Listrik Pascabayar",
    "multifinance": "Angsuran Kredit",
    "pdam": "Air PDAM",
    "phone-credit-postpaid": "Pulsa Pascabayar"
  }.with_indifferent_access

  PAYMENT_METHOD_MAPPER = {
    deposit: 'BukaDompet',
    atm: 'Transfer Bank',
    virtual_account: 'Transfer Virtual Account',
    credit_card: 'Kartu Visa/Mastercard/JCB/AMEX',
    kredivo: 'Kredivo',
    akulaku: 'BukaCicilan with Akulaku',
    dana: 'DANA',
    single_qr: 'Single QR Payment',
    pickup_cash: 'Jemput Tunai',
    bca_klikpay: 'BCA KlikPay (KlikBCA Individu)',
    mandiri_clickpay: 'Mandiri Clickpay',
    mandiri_ecash: 'LinkAja',
    cimb_clicks: 'CIMBClicks/RekPonsel/QRGoMobile',
    indomaret: 'Indomaret',
    alfamart: 'Alfamart',
    pospay: 'Pos Indonesia',
    voucher: 'Voucher',
    bri_e_pay: 'BRI E-Pay',
    partner: 'Partner',
    corporate: 'Corporate',
    replacement: 'Penggantian Barang',
    bukalapak_agent: 'Mitra Bukalapak',
    bca_oneklik: 'OneKlik',
    mandiri_pay: 'Mandiri Pay',
    mitra_bukalapak: 'Mitra - Bukalapak',
    mitra_brilink: 'Mitra BRILink',
    mitra_cod: 'Mitra COD',
    paylater: 'BayarNanti'
  }

  TRANSACTION_DETAILS_LABEL = {
    "transactions": "Tagihan",
    "dana_voucher": "Potongan Voucher Dana",
    "payment": "Kode Unik/Biaya Pelayanan",
    "payment_transfer": "Kode Unik",
    "payment_akulaku": "Biaya Pelayanan",
    "payment_kredivo": "Biaya Pelayanan",
    "payment_bca_klikpay": "Biaya Pelayanan",
    "payment_credit_card": "Biaya Pelayanan",
    "promo_payment": "Promo",
    "voucher": "Potongan Voucher",
    "wallet": "Bayar Sebagian dengan Dompet",
    "priority_buyer": "Pembeli Prioritas",
    "partner_reductions": "Potongan Saldo DANA",
    "buffer": "Pembulatan Transaksi",
    "others": "Biaya Lain-Lain"
  }

  module BpjsKesehatanReceipt
    PAGE_SIZE = 'A4'
    LAYOUT = 'vp_p2p.html.haml'
    TEMPLATE = 'receipts/bpjs_kesehatan.html.haml'
    FOOTER_TEMPLATE = 'receipts/footer.html.haml'
  end

  def render(file_path, utility_object = self, partial_view = "")
    Haml::Engine.new(File.read("#{file_path}.html.haml")).render(utility_object) do
      partial_view
    end
  end

  def money(int)
    rp = int.abs.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
    rp = 'Rp' + rp

    return '-' + rp if int < 0
    return rp
  end

  def build_period(period)
    first_period = period.first
    last_period = period.last

    return I18n.l(first_period, format: '%B %Y') if period.length == 1

    if first_period.year == last_period.year
      "#{I18n.l(first_period, format: '%B')} - #{I18n.l(last_period, format: '%B')} #{first_period.year}"
    else
      "#{I18n.l(first_period, format: '%B %Y')} - #{I18n.l(last_period, format: '%B %Y')}"
    end
  end

  def download_link(remote_id, product_type)
    product_type = 'postpaid_electricity' if product_type == 'electricity_postpaid'
    "https://www.bukalapak.com/payment/#{product_type.underscore}/transactions/#{remote_id}/proof_of_payment?force_desktop_view=1"
  end
end
