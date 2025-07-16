module Action
  module ElectricityTransaction
    class OnsiteNotif < Action::PostpaidTransaction::OnsiteNotif
      include ApplicationHelper
      include Postpaid::Constant
      include PaymentIdHelper

      private

      def run?
        # for non-agent transaction, send notif on remitted or failed
        # for agent transaction, send notif on processed, remitted, or failed
        super && (@transaction.agent? || @status != BUKALAPAK_PROCESSED)
      end

      def get_processed_payload
        # agent transaction payload
        {
          title: "Hore! Pembayaran Kamu Berhasil 🎉",
          body: "Saat ini, pembayaran tagihan PLN no. transaksi #{get_payment_id(@transaction)} sedang diproses. Silakan tunggu.",
          image: nil,
          url: "/transaksi/electricity_postpaid/#{@transaction.id}",
          tag: "agent-electricity-postpaid-processed",
          target: "agent"
        }
      end

      def get_remit_payload
        if @transaction.agent?
          {
            title: "Cihuy! Pembayaran Listrik Berhasil 👍",
            body: "Lihat detail pembayaran tagihan PLN untuk no. #{@transaction.customer_number} di sini. Terima kasih!",
            image: nil,
            url: "/transaksi/electricity_postpaid/#{@transaction.id}",
            tag: "agent-electricity-postpaid-remitted",
            target: "agent"
          }
        else
          if recurrent?(@transaction)
            title = 'Transaksi Rutin Kamu Berhasil'
            body = "Transaksi rutin untuk Listrik Pascabayar periode #{@transaction.bill_period} berhasil diproses."
            tag = 'electricity-postpaid-recurrent-remitted'
          else
            title = 'Transaksi Listrik Pascabayar Berhasil'
            body = "Transaksi Listrik Pascabayar kamu periode #{@transaction.bill_period} sudah diproses."
            tag = 'electricity-postpaid-remitted'
          end
          {
            title: title,
            body: body,
            image: nil,
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices/#{@transaction.invoice_id}",
            tag: tag,
            target: "normal"
          }
        end
      end

      def get_refund_payload
        if @transaction.agent?
          {
            title: "Maaf, Pembayaran Listrik Tidak Berhasil",
            body: "Saldo yang terpotong untuk no. transaksi #{get_payment_id(@transaction)} akan segera dikembalikan. Terima kasih.",
            image: nil,
            url: "/transaksi/electricity_postpaid/#{@transaction.id}",
            tag: "agent-electricity-postpaid-refunded",
            target: "agent"
          }
        else
          if recurrent?(@transaction)
            title = 'Transaksi Rutin Tidak Berhasil Diproses'
            body = "Uang pembayaran transaksi rutin Listrik Pascabayar akan dikembalikan ke BukaDompet kamu."
            tag = 'electricity-postpaid-recurrent-refunded'
          else
            title = 'Maaf, Transaksi Kamu Tidak Bisa Diproses'
            body = "Pembayaran Listrik Pascabayar #{money(@transaction.amount)} akan dikembalikan ke DANA/limit kartu kredit/Saldo kamu."
            tag = 'electricity-postpaid-refunded'
          end
          {
            title: title,
            body: body,
            image: nil,
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices/#{@transaction.invoice_id}",
            tag: tag,
            target: "normal"
          }
        end
      end
    end
  end
end
