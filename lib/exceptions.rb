module Exceptions
  # Base of electricity postpaid action error
  class PostpaidError < StandardError; end
  class InternalError < StandardError; end

  class BukalapakConnectionError < InternalError
    attr_reader :error_code, :http_code, :message

    def initialize(message)
      @message = message
      @error_code = 18101
      @http_code = 500
    end
  end

  # TODO: Currently not in used. To be removed?
  # class SepulsaFailed < PostpaidError
  #   attr_reader :error_code, :http_code, :message

  #   def initialize(response_code)
  #     @message = error_message(response_code)
  #     @error_code = 18102
  #     @http_code = 422
  #   end

  #   private

  #   def error_message(response_code)
  #     case response_code
  #     when "20"
  #       "Nomor tidak terdaftar / tagihan hingga bulan yang dipilih sudah lunas"
  #     when "21", "50"
  #       "Tagihan tidak ditemukan atau sudah dibayar"
  #     when "22", "23", "24", "25", "99"
  #       "Terjadi kesalahan pada sistem"
  #     when 20
  #       "Nomor tidak terdaftar"
  #     else
  #       "Terjadi kesalahan pada sistem"
  #     end
  #   end
  # end

  # TODO: Currently not in used. To be removed?
  # class NilCache < PostpaidError
  #   attr_reader :error_code, :http_code, :message

  #   def initialize
  #     @message = "Inquire customer number first"
  #     @error_code = 18103
  #     @http_code = 422
  #   end
  # end

  class InvalidStatusError < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(message = "Status not valid")
      @message = message
      @error_code = 18104
      @http_code = 422
    end
  end

  class CreateTransactionError < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Error create postpaid transaction"
      @error_code = 18105
      @http_code = 422
    end
  end

  class CannotProcessTransaction < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Cannot processed transaction"
      @error_code = 18106
      @http_code = 422
    end
  end

  class UnauthorizedUser < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(signed_in: false)
      if signed_in
        @message = "Kamu tidak dapat mengakses halaman ini"
      else
        @message = "Untuk mengakses halaman ini, silakan login lebih dahulu"
      end
      @error_code = 18107
      @http_code = 401
    end
  end

  class TransactionNotFound < InternalError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Transaction not found"
      @error_code = 18108
      @http_code = 404
    end
  end

  class CannotConfirmTransaction < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Cannot confirm transaction"
      @error_code = 18109
      @http_code = 422
    end
  end

  # TODO: Currently not in used. To be removed?
  # class TransactionNotProcessed < PostpaidError
  #   attr_reader :error_code, :http_code, :message

  #   def initialize
  #     @message = "Transaction is not processed"
  #     @error_code = 18110
  #     @http_code = 422
  #   end
  # end

  class ClosedTimeError < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(time_close, time_open)
      @message = "Service is closed from #{time_close.strftime('%H:%M')} - #{time_open.strftime('%H:%M')} WIB"
      @error_code = 18111
      @http_code = 422
    end
  end

  class InvalidPaymentPeriod < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Invalid payment period"
      @error_code = 18112
      @http_code = 422
    end
  end

  class PartnerTransactionNotFound < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Transaction not found in partner"
      @error_code = 18113
      @http_code = 422
    end
  end

  class InvalidPdamOperator < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Operator ID Not Found"
      @error_code = 18114
      @http_code = 422
    end
  end

  class CannotManualConfirmTransaction < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Transaction cannot be confirmed manually"
      @error_code = 18115
      @http_code = 422
    end
  end

  class CannotDeleteOperator < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Cannot delete operator"
      @error_code = 18116
      @http_code = 409
    end
  end

  class UnregisteredNumber < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(message = 'Nomor tidak terdaftar. Coba periksa lagi, yuk.')
      @message = message
      @error_code = 18117
      @http_code = 422
    end
  end

  class BillAlreadyPaid < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(message = 'Tagihan tidak ditemukan atau sudah dibayar.')
      @message = message
      @error_code = 18118
      @http_code = 422
    end
  end

  class TransactionCannotBeDone < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = 'Transaksi tidak dapat dilakukan. Cobalah beberapa saat lagi.'
      @error_code = 18119
      @http_code = 422
    end
  end

  class InvalidPhoneNumber < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Nomor telepon tidak valid"
      @error_code = 18120
      @http_code = 422
    end
  end

  class UnsupportedProvider < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Operator belum tersedia"
      @error_code = 18121
      @http_code = 422
    end
  end

  class InactiveProvider < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Operator mengalami gangguan."
      @error_code = 18122
      @http_code = 422
    end
  end

  # TODO: Currently not in used. To be removed?
  # class InvalidMultifinanceBiller < PostpaidError
  #   attr_reader :error_code, :http_code, :message

  #   def initialize
  #     @message = "Biller code unlisted"
  #     @error_code = 18123
  #     @http_code = 422
  #   end
  # end

  # TODO: Currently not in used. To be removed?
  # class CannotDeleteBiller < PostpaidError
  #   attr_reader :error_code, :http_code, :message

  #   def initialize
  #     @message = "Cannot delete biller, its being refered by transactions"
  #     @error_code = 18124
  #     @http_code = 409
  #   end
  # end

  class AccountSuspended < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(message = 'Nomor terblokir.')
      @message = message
      @error_code = 18125
      @http_code = 422
    end
  end

  class PartnerIssue < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(message = 'Layanan ini sedang tidak tersedia.')
      @message = message
      @error_code = 18126
      @http_code = 422
    end
  end

  # TODO: Currently not in used. To be removed?
  # class ContactMultifinanceOffice < PostpaidError
  #   attr_reader :error_code, :http_code, :message

  #   def initialize
  #     @message = 'Terjadi kesalahan. Mohon hubungi penyedia kredit'
  #     @error_code = 18127
  #     @http_code = 422
  #   end
  # end

  # TODO: Currently not in used. To be removed?
  # class MultifinanceLastInstallment < PostpaidError
  #   attr_reader :error_code, :http_code, :message

  #   def initialize
  #     @message = 'Anda sudah mencapai tagihan terakhir. Mohon hubungi penyedia kredit'
  #     @error_code = 18128
  #     @http_code = 422
  #   end
  # end

  class BillerNotFound < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Biller ID Not Found"
      @error_code = 18129
      @http_code = 404
    end
  end

  class PartnerNotFound < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(message = "Partner ID Not Found")
      @message = message
      @error_code = 18210
      @http_code = 422
    end
  end

  class AtLeastOnePartnerActive < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "1 partner harus aktif dalam satu waktu"
      @error_code = 18211
      @http_code = 404
    end
  end

  # TODO: Currently not in used. To be removed?
  # class BukopinFailed < PostpaidError
  #   attr_reader :error_code, :http_code, :message

  #   def initialize(response_code, idpel)
  #     @message = error_message(response_code, idpel)
  #     @error_code = 18130
  #     @http_code = 422
  #   end

  #   private

  #   def get_month_name
  #     today = Date.today.strftime('%m')
  #     months = {
  #       "01" => "Januari",
  #       "02" => "Februari",
  #       "03" => "Maret",
  #       "04" => "April",
  #       "05" => "Mei",
  #       "06" => "Juni",
  #       "07" => "Juli",
  #       "08" => "Agustus",
  #       "09" => "September",
  #       "10" => "Oktober",
  #       "11" => "November",
  #       "12" => "Desember"
  #     }
  #     months[today]
  #   end

  #   def error_message(response_code, idpel)
  #     case response_code
  #     when "0014"
  #       "IDPEL yang anda masukan salah, mohon teliti kembali"
  #     when "0016", "0077"
  #       "Konsumen IDPEL #{idpel} diblokir, hubungi PLN"
  #     when "0088"
  #       "Tagihan sudah terbayar"
  #     when "0089"
  #       "Tagihan bulan #{get_month_name} belum tersedia"
  #     else
  #       "Terjadi kesalahan pada sistem"
  #     end
  #   end
  # end

  class MissingParameter < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = 'Missing required parameter'
      @error_code = 18131
      @http_code = 422
    end
  end

  # TODO: Currently not in used. To be removed?
  # class BillGenerateFail < PostpaidError
  #   attr_reader :error_code, :http_code, :message

  #   def initialize(message = 'Pembuatan kode bayar gagal dilakukan karena terjadi kesalahan pada sistem')
  #     @message = generate_error_message(message)
  #     @error_code = 18134
  #     @http_code = 422
  #   end

  #   def generate_error_message(response_message)
  #     case response_message.strip.upcase
  #     when "DATA TIDAK DITEMUKAN", "DUPLIKASI DATA / DATA TIDAK DITEMUKAN"
  #       "Maaf, Datamu Tidak Ketemu. Silakan periksa kembali nomor rangka dan nomor KTP yang telah dimasukkan."
  #     when "BATAS PEMBAYARAN 6 BULAN SEBELUM JATUH TEMPO BELUM SAAT NYA MEMBAYAR"
  #       "Maaf, Belum Bisa Bayar. Pastikan batas pembayaran PKB-mu sekitar 6 bulan sebelum tanggal jatuh tempo."
  #     when "STNK 5 TAHUN MASA BERLAKU HABIS, PEMBAYARAN HARUS DILAKUKAN DI SAMSAT INDUK"
  #       "Maaf, Tidak Bisa Bayar. STNK-mu telah habis masa berlaku lima tahunan. Silakan bayar di Samsat Induk."
  #     when "CHECK.. PENULISAN NOMOR RANGKA SALAH"
  #       "Maaf, No. Rangka Salah. Silakan periksa kembali nomor rangka kendaraan yang telah dimasukkan."
  #     when "CHECK.. PENULISAN NIK SALAH"
  #       "Maaf, No. NIK Salah. Silakan periksa kembali nomor induk kependudukkan yang telah dimasukkan."
  #     when "NILAI JUAL BELUM TERDAFTAR 2 LAKUKAN PEMBAYARAN KE SAMSAT TERDEKAT", "KENDARAAN DI PROTEK, LAKUKAN PENGECEKAN/PEMBAYARAN GANTI PEMILIK DI SAMSAT KEND. TERDAFTAR"
  #       "Maaf, Terjadi Kendala. Silakan langsung datangi Samsat terdekat untuk melakukan pembayaran."
  #     when "PEMBAYARAN SUDAH DILAKUKAN HARI INI"
  #       "Kamu Sudah Bayar Kok! Silakan cek emailmu yang terdaftar di Bukalapak untuk menemukan bukti bayar."
  #     when "TIDAK BERLAKU UNTUK KENDARAAN DENGAN PLAT B"
  #       "Maaf, Tidak Bisa Bayar. E-Samsat Jawa Barat tidak melayani kendaraan berplat B. Silakan bayar di Samsat terdekat."
  #     when "PEMBAYARAN HANYA DAPAT DILAKUKAN PUKUL 00.00-22.00"
  #       "Maaf, Kami Belum Buka. Silakan coba kembali antara pukul 00.00 sampai 22.00. Terima kasih! "
  #     else
  #       'Maaf, Terjadi Kendala. Silakan langsung datangi Samsat terdekat untuk melakukan pembayaran.'
  #     end
  #   end

  # end

  class InvalidCreditCardNumber < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = 'Nomor kartu kredit tidak valid'
      @error_code = 18135
      @http_code = 422
    end
  end

  # TODO: Currently not in used. To be removed?
  # class InvalidBankIssuer < PostpaidError
  #   attr_reader :error_code, :http_code, :message

  #   def initialize
  #     @message = 'Bank penerbit tidak tersedia'
  #     @error_code = 18136
  #     @http_code = 422
  #   end
  # end

  class InsufficientAmount < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = 'Nominal pembayaran tidak boleh kurang dari minimum pembayaran'
      @error_code = 18137
      @http_code = 422
    end
  end

  class InvalidCreditCardNumberLength < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = 'Sistem tidak dapat memproses nomor kartu'
      @error_code = 18138
      @http_code = 422
    end
  end

  # TODO: Currently not in used. To be removed?
  # class InvalidPlateNumber < PostpaidError
  #   attr_reader :error_code, :http_code, :message

  #   def initialize()
  #     @message = "Mohon maaf, untuk sementara waktu kendaraan wilayah Jawa Barat dengan plat B belum dapat melakukan pembayaran pajak kendaraan bermotor di Bukalapak"
  #     @error_code = 18139
  #     @http_code = 422
  #   end
  # end

  class TransactionNotPaid < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(msg="Transaction is not paid")
      @message = msg
      @error_code = 18142
      @http_code = 422
    end
  end

  class DoubleValueError < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(val)
      @message = "Value #{val} sudah diisi"
      @error_code = 18140
      @http_code = 422
    end
  end

  class ManualCheckError < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(partner)
      @message = "Transaksi tidak dapat di cek statusnya, mohon di follow up ke partner #{partner}"
      @error_code = 18141
      @http_code = 422
    end
  end

  class InvalidCustomerNumber < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(message = "Invalid Customer Number")
      @message = message
      @error_code = 18143
      @http_code = 422
    end
  end

  class FeatureToggledOff < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = 'Produk ini sedang tidak tersedia'
      @error_code = 18198
      @http_code = 422
    end
  end

  class DefaultError < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = 'Terjadi kesalahan pada sistem'
      @error_code = 18199
      @http_code = 422
    end
  end

  class BalanceTypeNotFound < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = 'Tipe saldo tidak sesuai'
      @error_code = 18200
      @http_code = 422
    end
  end

  class InvalidParameterError < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(msg = 'Info yang kamu masukkan salah :( mohon diteliti kembali')
      @message = msg
      @error_code = 181200
      @http_code = 422
    end
  end

  class AmountExceedsLimit < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(msg = 'Tagihan yang dibayar maksimum Rp 50.000.000')
      @message = msg
      @error_code = 181201
      @http_code = 422
    end
  end

  class TransactionCreatedExceedsLimit < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(msg = 'Maaf, transaksinya belum berhasil dibuat. Coba sebentar lagi ya.') #TBC
      @message = msg
      @error_code = 18206
      @http_code = 422
    end
  end

  class CircuitOpen < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(msg = 'Layanannya lagi ditutup. Coba lagi nanti, ya.')
      @message = msg
      @error_code = 18218
      @http_code = 422
    end
  end

  class GeneralError < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(msg = 'General error')
      @message = msg
      @error_code = 18219
      @http_code = 500
    end
  end

  # BTS_KUBE
  module BtsKube

    class InquiryFailed < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(msg = 'Inkuiri Gagal')
        @message = msg
        @error_code = 18202
        @http_code = 422
      end
    end

    class InquiryError < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(msg = 'Inkuiri Gagal')
        @message = msg
        @error_code = 18203
        @http_code = 422
      end
    end

    class CannotConnectToBtsKube < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(msg = 'Cannot connect to bts kube, retrying')
        @message = msg
        @error_code = 18204
        @http_code = 502
      end
    end

    class PaymentError < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(msg = 'Pembayaran DBS Gagal')
        @message = msg
        @error_code = 18204
        @http_code = 422
      end
    end

    class ConfirmError < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(msg = 'Confirm DBS Gagal')
        @message = msg
        @error_code = 18205
        @http_code = 422
      end
    end

  end

  class TemplateNotFound < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Template Not Found"
      @error_code = 18207
      @http_code = 404
    end
  end

  class BillerUnavailable < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Biller sedang dalam masa perbaikan"
      @error_code = 18208
      @http_code = 422
    end
  end

  class NonIntegerValue < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Value is a non integer object"
      @error_code = 18210
      @http_code = 500
    end
  end

  class SocketConnectionTimeout < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Timeout while listening to socket"
      @error_code = 18211
      @http_code = 422
    end
  end

  class KeyNotAllowed < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(key)
      @message = "Keystore not allow usage of unregistered key #{key}"
      @error_code = 18212
      @http_code = 500
    end
  end

  class AmountMismatch < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(bl_amount: nil, partner_amount: nil)
      @message = "Amount tidak sama, tercatat #{bl_amount}, tetapi #{partner_amount} di partner"
      @error_code = 18213
      @http_code = 422
    end
  end

  class SignOnFailed < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Periode Login telah berakhir. Silahkan login ulang."
      @error_code = 18214
      @http_code = 422
    end
  end

  class MaxInquiryAttemptExceeded < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Saat ini tidak bisa melakukan inkuiri, coba lagi beberapa saat ya."
      @error_code = 18220
      @http_code = 429 # Too Many Requests - https://tools.ietf.org/html/rfc6585#section-4
    end
  end

  class BillExceedLimit < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Tagihan melebihi batas maksimum."
      @error_code = 18221
      @http_code = 422
    end
  end

  class InquiryFailed < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Inquiry gagal"
      @error_code = 18222
      @http_code = 422
    end
  end

  class UnsupportedType < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(message = 'Tidak dapat memproses file dengan tipe yang diberikan')
      @message = message
      @error_code = 18307
      @http_code = 422
    end
  end

  class RecordNotSetError < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(field = 'data')
      @message = "#{field} belum di set"
      @error_code = 18308
      @http_code = 422
    end
  end

  class PartnerClassNotFound < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize(message = 'No partner class available for this partner')
      @message = message
      @error_code = 18309
      @http_code = HTTP_STATUS_UNPROCESSABLE_ENTITY
    end
  end

  module Bukopin

    class Network < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Aduh maaf sedang ada gangguan, coba lagi beberapa saat, ya! ;)')
        @message = message
        @error_code = 18213
        @http_code = 422
      end
    end

    class Inquiry < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Inkuiri Gagal')
        @message = message
        @error_code = 18209
        @http_code = 422
      end
    end

    class Payment < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Payment Gagal')
        @message = message
        @error_code = 18210
        @http_code = 422
      end
    end

    # TODO: Currently not in used. To be removed?
    class Reversal < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Reversal Gagal')
        @message = message
        @error_code = 18211
        @http_code = 422
      end
    end

    # TODO: Currently not in used. To be removed?
    class Timeout < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Aduh maaf sedang ada gangguan, coba lagi beberapa saat, ya! ;)')
        @message = message
        @error_code = 18214
        @http_code = 503
      end
    end

    class Unauthorized < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Aduh maaf sedang ada gangguan, coba lagi beberapa saat, ya! ;)')
        @message = message
        @error_code = 18215
        @http_code = 401
      end
    end

    class InvalidSecurityData < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Aduh maaf sedang ada gangguan, coba lagi beberapa saat, ya! ;)')
        @message = message
        @error_code = 18216
        @http_code = 403
      end
    end
  end

  module Visa
    class GeneralError < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize
        @message = 'Aduh maaf sedang ada gangguan, coba lagi beberapa saat, ya! ;)'
        @error_code = 18300
        @http_code = 422
      end
    end

    class InvalidVisaCard < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize
        @message = 'Nomor kartu kredit VISA tidak valid'
        @error_code = 18301
        @http_code = 422
      end
    end

    class InvalidCreditCardNumber < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize
        @message = 'Nomor kartu kredit tidak valid'
        @error_code = 18302
        @http_code = 422
      end
    end

    # class CreditCardExpired < PostpaidError
    #   attr_reader :error_code, :http_code, :message

    #   def initialize
    #     @message = 'Kartu kredit telah kedaluwarsa'
    #     @error_code = 18303
    #     @http_code = 422
    #   end
    # end

    class NoToken < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize
        @message = 'Tidak dapat melakukan transaksi dengan nomor kartu kredit ini'
        @error_code = 18304
        @http_code = 422
      end
    end

    class PayoutsFailed < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Payouts Failed')
        @message = message
        @error_code = 18305
        @http_code = 422
      end
    end

    class ConfirmFailed < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Gagal confirm transaksi')
        @message = message
        @error_code = 18306
        @http_code = 422
      end
    end
  end

  module BNI
    class TimeoutResponse < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Got timeout message on response body')
        @message = message
        @error_code = 18350
        @http_code = 500
      end
    end
  end

  class AutoswitchGroupNotFound < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Autoswitch Group Not Found"
      @error_code = 18360
      @http_code = 404
    end
  end

  class AutoswitchGroupMemberNotFound < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Autoswitch Group Member Not Found"
      @error_code = 18361
      @http_code = 404
    end
  end

  class DuplicateAutoswitchGroupMember < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Duplicate Autoswitch Group Member"
      @error_code = 18362
      @http_code = 422
    end
  end

  class DuplicateAutoswitchGroup < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Duplicate Autoswitch Group Name"
      @error_code = 18363
      @http_code = 422
    end
  end

  class AutoswitchGroupInactive < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Autoswitch Group Inactive"
      @error_code = 18364
      @http_code = 422
    end
  end

  module ReprocessingJob
    class JobIsProcessedError < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize
        @message = "Cannot download transaction because the job is still on progress"
        @error_code = 18365
        @http_code = HTTP_STATUS_UNPROCESSABLE_ENTITY
      end
    end

    class TransactionNotFound < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize
        @message = "Transaction not found"
        @error_code = 18366
        @http_code = HTTP_STATUS_UNPROCESSABLE_ENTITY
      end
    end

    class JobNotFound < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize
        @message = "Job not found"
        @error_code = 18367
        @http_code = HTTP_STATUS_UNPROCESSABLE_ENTITY
      end
    end

    class MoreThanOneDayError < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize
        @message = "Date range cannot be more than 1 days"
        @error_code = 18368
        @http_code = HTTP_STATUS_UNPROCESSABLE_ENTITY
      end
    end

    class InvalidDateError < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize
        @message = "Date is not valid"
        @error_code = 18369
        @http_code = HTTP_STATUS_UNPROCESSABLE_ENTITY
      end
    end

    class ExceedMaxDateError < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize
        @message = "You can only pick/choose previous days"
        @error_code = 18370
        @http_code = HTTP_STATUS_UNPROCESSABLE_ENTITY
      end
    end

    class UnstuckJobIsProcessedError < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize
        @message = "Cannot reprocess transaction because another job with same date is running"
        @error_code = 18371
        @http_code = HTTP_STATUS_UNPROCESSABLE_ENTITY
      end
    end

    class UnstuckTransactionNotFoundError < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize
        @message = "Cannot reprocess transaction because no transaction found"
        @error_code = 18372
        @http_code = HTTP_STATUS_UNPROCESSABLE_ENTITY
      end
    end
  end

  module Dji
    class ErrTimeout < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Aduh maaf sedang ada gangguan, coba lagi beberapa saat, ya! ;)')
        @message = message
        @error_code = 18374
        @http_code = HTTP_STATUS_UNPROCESSABLE_ENTITY
      end
    end

    class HostUnreachableError < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Aduh maaf sedang ada gangguan, coba lagi beberapa saat, ya! ;)')
        @message = message
        @error_code = 18374
        @http_code = HTTP_STATUS_UNPROCESSABLE_ENTITY
      end
    end

    class MissingPartnerTransactionId < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Missing Partner Transaction Id')
        @message = message
        @error_code = 18375
        @http_code = HTTP_STATUS_UNPROCESSABLE_ENTITY
      end
    end
  end

  module Thor

    class Unauthorized < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Unauthorized')
        @message = message
        @error_code = 18376
        @http_code = 401
      end
    end

    class Forbidden < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Forbidden')
        @message = message
        @error_code = 18377
        @http_code = 403
      end
    end

    class DefaultError < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Terjadi kesalahan pada sistem')
        @message = message
        @error_code = 18378
        @http_code = 422
      end
    end

    class PdamBillCanOnlyBePaidDirectly < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Tagihan hanya bisa dibayar di PDAM.')
        @message = message
        @error_code = 18379
        @http_code = 422
      end
    end

    class CutOff < PostpaidError
      attr_reader :error_code, :http_code, :message

      def initialize(message = 'Cut Off System')
        @message = message
        @error_code = 18380
        @http_code = 422
      end
    end
  end

  class AutoswitchGroupMemberSettingNotFound < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Autoswitch Group Member Setting Not Found"
      @error_code = 18381
      @http_code = 404
    end
  end

  class CommissionNotFound < InternalError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "Commission not found"
      @error_code = 18382
      @http_code = 404
    end
  end

  class OperatorNotFound < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "PDAM Operator not found"
      @error_code = 18382
      @http_code = 404
    end
  end

  class CommissionSettingNotFound < PostpaidError
    attr_reader :error_code, :http_code, :message

    def initialize
      @message = "PDAM Operator Commission Setting not found"
      @error_code = 18383
      @http_code = 404
    end
  end
end
