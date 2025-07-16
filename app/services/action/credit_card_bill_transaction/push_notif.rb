module Action
  module CreditCardBillTransaction
    class PushNotif < Action::PostpaidTransaction::PushNotif
      include ApplicationHelper
      include Postpaid::Constant

      private

      def run?
        super && @status != BUKALAPAK_PROCESSED
      end

      def get_remit_payload
        {
          headings: "Transaksi Tagihan Kartu Kredit Berhasil",
          contents: "Transaksi Tagihan Kartu Kredit kamu (***#{@transaction.card_number.slice(-4,4)}) periode #{@transaction.bill_period} sudah diproses.",
          tag: "credit-card-bill-remitted",
          url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices/#{@transaction.invoice_id}",
          target: 'normal'
        }
      end

      def get_refund_payload
        {
          headings: "Maaf, Transaksi Kamu Tidak Bisa Diproses",
          contents: "Pembayaran Tagihan Kartu Kredit #{money(@transaction.amount)} akan dikembalikan ke DANA/limit kartu kredit/Saldo kamu.",
          tag: "credit-card-bill-refunded",
          url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices/#{@transaction.invoice_id}",
          target: 'normal'
        }
      end
    end
  end
end
