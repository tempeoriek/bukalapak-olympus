module Action
  module PhoneCreditTransaction
    class PushNotif < Action::PostpaidTransaction::PushNotif
      include ApplicationHelper
      include Postpaid::Constant

      private

      def run?
        super && @status != BUKALAPAK_PROCESSED
      end

      def get_remit_payload
        result = {
          tag: 'phone-credit-postpaid-remitted',
          url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices/#{@transaction.invoice_id}",
          target: 'normal'
        }
        if @transaction.recurrent?
          result.merge!({
            headings: 'Transaksi Rutin Kamu Berhasil Diproses',
            contents: "Hore! Transaksi Rutin Pulsa Pascabayar sebesar Rp#{money(@transaction.amount)} berhasil. Lihat detail transaksinya."
          })
        else
          result.merge!({
            headings: 'Transaksi Pulsa Pascabayar Berhasil',
            contents: "Pembayaran Pulsa Pascabayar kamu (#{get_censored_phone_number(@transaction.phone_number)}) periode #{@transaction.bill_period} sudah diproses."
          })
        end
        result
      end

      def get_refund_payload
        result = {
          tag: 'phone-credit-postpaid-refunded',
          url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices/#{@transaction.invoice_id}",
          target: 'normal'
        }
        if @transaction.recurrent?
          result.merge!({
            headings: 'Transaksi Rutin Tidak Berhasil Diproses',
            contents: "Pembayaran Transaksi Rutin Pulsa Pascabayar akan dikembalikan ke Saldo/DANA/limit kartu kamu.",
          })
        else
          result.merge!({
            headings: 'Maaf, Transaksi Kamu Tidak Bisa Diproses',
            contents: "Pembayaran Pulsa Pascabayar #{money(@transaction.total_amount)} akan dikembalikan ke DANA/limit kartu kredit/Saldo kamu."
          })
        end
        result
      end
    end
  end
end
