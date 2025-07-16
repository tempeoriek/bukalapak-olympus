module Action
  module PdamTransaction
    class PushNotif < Action::PostpaidTransaction::PushNotif
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
          headings: "Hore! Pembayaran Kamu Berhasil 🎉",
          contents: "Saat ini, pembayaran tagihan PDAM no. transaksi #{get_payment_id(@transaction)} sedang diproses. Silakan tunggu.",
          tag: "agent-pdam-processed",
          url: "/transaksi/pdam/#{@transaction.id}",
          target: "agent"
        }
      end

      def get_remit_payload
        if @transaction.agent?
          {
            headings: "Cihuy! Pembayaran PDAM Berhasil 👍",
            contents: "Lihat detail pembayaran tagihan PDAM untuk no. #{@transaction.customer_number} di sini. Terima kasih!",
            tag: "agent-pdam-remitted",
            url: "/transaksi/pdam/#{@transaction.id}",
            target: "agent"
          }
        else
          if recurrent?(@transaction)
            headings = 'Transaksi Rutin Kamu Berhasil'
            contents = "Transaksi rutin untuk Air PDAM periode #{@transaction.bill_period} berhasil diproses."
            tags = 'pdam-recurrent-remitted'
          else
            headings = 'Transaksi Air PDAM Berhasil'
            contents = "Transaksi Air PDAM kamu periode #{@transaction.bill_period} sudah diproses."
            tags = 'pdam-remitted'
          end
          {
            headings: headings,
            contents: contents,
            tag: tags,
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices/#{@transaction.invoice_id}",
            target: 'normal'
          }
        end
      end

      def get_refund_payload
        if @transaction.agent?
          {
            headings: "Maaf, Pembayaran PDAM Tidak Berhasil",
            contents: "Saldo yang terpotong untuk no. transaksi #{get_payment_id(@transaction)} akan segera dikembalikan. Terima kasih.",
            tag: "agent-pdam-refunded",
            url: "/transaksi/pdam/#{@transaction.id}",
            target: "agent"
          }
        else
          if recurrent?(@transaction)
            headings = 'Transaksi Rutin Tidak Berhasil Diproses'
            contents = "Uang pembayaran transaksi rutin Air PDAM akan dikembalikan ke BukaDompet kamu."
            tags = 'pdam-recurrent-refunded'
          else
            headings = 'Maaf, Transaksi Kamu Tidak Bisa Diproses'
            contents = "Pembayaran Air PDAM #{money(@transaction.amount)} akan dikembalikan ke DANA/limit kartu kredit/Saldo kamu."
            tags = 'pdam-refunded'
          end
          {
            headings: headings,
            contents: contents,
            tag: tags,
            url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices/#{@transaction.invoice_id}",
            target: 'normal'
          }
        end
      end
    end
  end
end
