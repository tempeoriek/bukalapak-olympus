module Action
  module ElectricityTransaction
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
          contents: "Saat ini, pembayaran tagihan PLN no. transaksi #{get_payment_id(@transaction)} sedang diproses. Silakan tunggu.",
          tag: "agent-electricity-postpaid-processed",
          url: "/transaksi/electricity_postpaid/#{@transaction.id}",
          target: "agent"
        }
      end

      # Prepare payloads to be used in parent `run!`
      def get_remit_payload
        if  @transaction.agent?
          {
            headings: "Cihuy! Pembayaran Listrik Berhasil 👍",
            contents: "Lihat detail pembayaran tagihan PLN untuk no. #{@transaction.customer_number} di sini. Terima kasih!",
            tag: "agent-electricity-postpaid-remitted",
            url: "/transaksi/electricity_postpaid/#{@transaction.id}",
            target: "agent"
          }
        else
          if recurrent?(@transaction)
            headings = 'Transaksi Rutin Kamu Berhasil'
            contents = "Transaksi rutin untuk Listrik Pascabayar periode #{@transaction.bill_period} berhasil diproses."
            tags = 'electricity-postpaid-recurrent-remitted'
          else
            headings = 'Transaksi Listrik Pascabayar Berhasil'
            contents = "Transaksi Listrik Pascabayar kamu periode #{@transaction.bill_period} sudah diproses."
            tags = 'electricity-postpaid-remitted'
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
            headings: "Maaf, Pembayaran Listrik Tidak Berhasil",
            contents: "Saldo yang terpotong untuk no. transaksi #{get_payment_id(@transaction)} akan segera dikembalikan. Terima kasih.",
            tag: "agent-electricity-postpaid-refunded",
            url: "/transaksi/electricity_postpaid/#{@transaction.id}",
            target: "agent"
          }
        else
          if recurrent?(@transaction)
            headings = 'Transaksi Rutin Tidak Berhasil Diproses'
            contents = "Uang pembayaran transaksi rutin Listrik Pascabayar akan dikembalikan ke BukaDompet kamu."
            tags = 'electricity-postpaid-recurrent-refunded'
          else
            headings = 'Maaf, Transaksi Kamu Tidak Bisa Diproses'
            contents = "Pembayaran Listrik Pascabayar #{money(@transaction.amount)} akan dikembalikan ke DANA/limit kartu kredit/Saldo kamu."
            tags = 'electricity-postpaid-refunded'
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
