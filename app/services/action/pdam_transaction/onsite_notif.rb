module Action
  module PdamTransaction
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
          body: "Saat ini, pembayaran tagihan PDAM no. transaksi #{get_payment_id(@transaction)} sedang diproses. Silakan tunggu.",
          image: nil,
          url: "/transaksi/pdam/#{@transaction.id}",
          tag: "agent-pdam-processed",
          target: "agent"
        }
      end

      def get_remit_payload
        if @transaction.agent?
          {
            title: "Cihuy! Pembayaran PDAM Berhasil 👍",
            body: "Lihat detail pembayaran tagihan PDAM untuk no. #{@transaction.customer_number} di sini. Terima kasih!",
            image: nil,
            url: "/transaksi/pdam/#{@transaction.id}",
            tag: "agent-pdam-remitted",
            target: "agent"
          }
        else
          if recurrent?(@transaction)
            title = 'Transaksi Rutin Kamu Berhasil'
            body = "Transaksi rutin untuk Air PDAM periode #{@transaction.bill_period} berhasil diproses."
            tag = 'pdam-recurrent-remitted'
          else
            title = 'Transaksi Air PDAM Berhasil'
            body = "Transaksi Air PDAM kamu periode #{@transaction.bill_period} sudah diproses."
            tag = 'pdam-remitted'
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
            title: "Maaf, Pembayaran PDAM Tidak Berhasil",
            body: "Saldo yang terpotong untuk no. transaksi #{get_payment_id(@transaction)} akan segera dikembalikan. Terima kasih.",
            image: nil,
            url: "/transaksi/pdam/#{@transaction.id}",
            tag: "agent-pdam-refunded",
            target: "agent"
          }
        else
          if recurrent?(@transaction)
            title = 'Transaksi Rutin Tidak Berhasil Diproses'
            body = "Uang pembayaran transaksi rutin Air PDAM akan dikembalikan ke BukaDompet kamu."
            tag = 'pdam-recurrent-refunded'
          else
            title = 'Maaf, Transaksi Kamu Tidak Bisa Diproses'
            body = "Pembayaran Air PDAM #{money(@transaction.amount)} akan dikembalikan ke DANA/limit kartu kredit/Saldo kamu."
            tag = 'pdam-refunded'
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
