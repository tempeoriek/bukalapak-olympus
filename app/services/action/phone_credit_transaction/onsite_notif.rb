module Action
  module PhoneCreditTransaction
    class OnsiteNotif < Action::PostpaidTransaction::OnsiteNotif
      include ApplicationHelper
      include Postpaid::Constant

      private

      def run?
        super && @status != BUKALAPAK_PROCESSED
      end

      def get_remit_payload
        result = {
          image: nil,
          url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices/#{@transaction.invoice_id}",
          tag: 'phone-credit-postpaid-remitted',
          target: "normal"
        }
        if @transaction.recurrent?
          result.merge!({
            title: 'Transaksi Rutin Kamu Berhasil Diproses',
            body: "Hore! Transaksi Rutin Pulsa Pascabayar sebesar Rp#{money(@transaction.amount)} berhasil. Lihat detail transaksinya."
          })
        else
          result.merge!({
            title: 'Transaksi Pulsa Pascabayar Berhasil',
            body: "Pembayaran Pulsa Pascabayar kamu (#{get_censored_phone_number(@transaction.phone_number)}) periode #{@transaction.bill_period} sudah diproses."
          })
        end
        result
      end

      def get_refund_payload
        result = {
          image: nil,
          url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices/#{@transaction.invoice_id}",
          tag: 'phone-credit-postpaid-refunded',
          target: "normal"
        }
        if @transaction.recurrent?
          result.merge!({
            title: 'Transaksi Rutin Tidak Berhasil Diproses',
            body: "Pembayaran Transaksi Rutin Pulsa Pascabayar akan dikembalikan ke Saldo/DANA/limit kartu kamu.",
          })
        else
          result.merge!({
            title: 'Maaf, Transaksi Kamu Tidak Bisa Diproses',
            body: "Pembayaran Pulsa Pascabayar #{money(@transaction.total_amount)} akan dikembalikan ke DANA/limit kartu kredit/Saldo kamu."
          })
        end
        result
      end
    end
  end
end
