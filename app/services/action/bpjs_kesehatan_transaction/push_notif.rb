module Action
  module BpjsKesehatanTransaction
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
          contents: "Saat ini, pembayaran tagihan BPJS no. transaksi #{get_payment_id(@transaction)} sedang diproses. Silakan tunggu.",
          tag: "agent-bpjs-processed",
          url: "/transaksi/bpjs-kesehatan/#{@transaction.id}",
          target: "agent"
        }
      end

      # Prepare payloads to be used in parent `run!`
      def get_remit_payload
        if @transaction.agent?
          {
            headings: "Cihuy! Pembayaran BPJS Berhasil 👍",
            contents: "Lihat detail pembayaran tagihan BPJS untuk no. VA #{@transaction.customer_number} di sini. Terima kasih!",
            tag: "agent-bpjs-remitted",
            url: "/transaksi/bpjs-kesehatan/#{@transaction.id}",
            target: "agent"
          }
        else
          if recurrent?(@transaction)
            headings = 'Transaksi Rutin Kamu Berhasil'
            contents = "Transaksi rutin untuk BPJS Kesehatan periode #{@transaction.bill_period} berhasil diproses."
            tags = 'bpjs-recurrent-remitted'
          else
            headings = 'Transaksi BPJS Kesehatan Berhasil'
            contents = "Transaksi BPJS Kesehatan kamu periode #{@transaction.bill_period} sudah diproses."
            tags = 'bpjs-remitted'
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
            headings: "Maaf, Pembayaran BPJS Tidak Berhasil",
            contents: "Saldo yang terpotong untuk no. transaksi #{get_payment_id(@transaction)} akan segera dikembalikan. Terima kasih.",
            tag: "agent-bpjs-refunded",
            url: "/transaksi/bpjs-kesehatan/#{@transaction.id}",
            target: "agent"
          }
        else
          if recurrent?(@transaction)
            headings = 'Transaksi Rutin Tidak Berhasil Diproses'
            contents = "Uang pembayaran transaksi rutin BPJS Kesehatan akan dikembalikan ke BukaDompet kamu."
            tags = 'bpjs-recurrent-refunded'
          else
            headings = 'Maaf, Transaksi Kamu Tidak Bisa Diproses'
            contents = "Pembayaran BPJS Kesehatan #{money(@transaction.amount)} akan dikembalikan ke DANA/limit kartu kredit/Saldo kamu."
            tags = 'bpjs-refunded'
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
