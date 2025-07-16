# frozen_string_literal: true

module Channel
  module Tektaya
    module Helpers
      module ResponseCode
        RESPONSE_CODE_STATUS = {
          '00' => :success, # Transaksi Sukses
          '01' => :failed, # Saldo Tidak Mencukupi
          '02' => :failed, # Kode Agent / Mitra Tidak Ada
          '04' => :failed, # Password Salah
          '05' => :failed, # Error Lain-Lain
          '09' => :failed, # Message Error
          '10' => :failed, # Billing Tidak Ada
          '11' => :failed, # Parameter Data Salah
          '12' => :failed, # Transaksi Ditolak
          '13' => :failed, # Nominal Salah
          '14' => :failed, # ID Pelanggan Tidak Ada
          '15' => :failed, # No Meter / ID Pelanggan Tidak Ada
          '16' => :pending, # Timeout, Server Mitra Tidak Respon
          '17' => :failed, # Tunggakan Melebihi Maksimal
          '33' => :failed, # ID Pelanggan Tidak Terdaftar
          '41' => :failed, # Batasan Minimum Pembelian
          '42' => :failed, # Batasan Maksimum Pembelian
          '47' => :failed, # KWh Melebihi Batas Maksimum
          '51' => :failed, # Transaksi Gagal
          '54' => :failed, # Tagihan Sudah Lunas
          '55' => :failed, # Tagihan Belum Tersedia
          '63' => :failed, # Payment Not Found
          '67' => :failed, # Biller Error, Suspend Credit
          '68' => :pending, # Biller Timeout, Suspend Credit
          '72' => :failed, # Kwh Melebihi Batas Maksimum
          '74' => :failed, # ID Pelanggan Diblokir
          '77' => :failed, # ID Pelanggan Diblokir
          '88' => :failed, # Tagihan Sudah Lunas
          '89' => :failed, # Link Down
          '91' => :failed, # Koneksi Ke Biller Putus
          '92' => :failed, # Message Tidak Dapat Di Routing
          '94' => :failed, # Duplikat Stan
          '96' => :failed, # System Biller Error
          '97' => :failed, # Cut Off
          '99' => :failed # Error Lain-Lain
        }.freeze

        def get_status_from_response_code(response_code)
          RESPONSE_CODE_STATUS[response_code.to_s]
        end
      end
    end
  end
end
