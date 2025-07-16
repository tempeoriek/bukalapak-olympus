module Action
  module CreditCardBillTransaction
    class OnsiteNotif < Action::PostpaidTransaction::OnsiteNotif
      include ApplicationHelper
      include Postpaid::Constant

      private

      def run?
        super && @status != BUKALAPAK_PROCESSED
      end

      def get_remit_payload
        {
          title: "Transaksi Tagihan Kartu Kredit Berhasil",
          body: "Transaksi Tagihan Kartu Kredit kamu (***#{@transaction.card_number.slice(-4,4)} periode #{@transaction.bill_period} sudah diproses.",
          image: nil,
          url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices/#{@transaction.invoice_id}",
          tag: "credit-card-bill-remitted",
          target: "normal"
        }
      end

      def get_refund_payload
        {
          title: "Maaf, Transaksi Kamu Tidak Bisa Diproses",
          body: "Pembayaran Tagihan Kartu Kredit #{money(@transaction.amount)} akan dikembalikan ke DANA/limit kartu kredit/Saldo kamu.",
          image: nil,
          url: "#{ENV["BUKALAPAK_WEB_URL"]}/payment/invoices/#{@transaction.invoice_id}",
          tag: 'credit-card-bill-refunded',
          target: "normal"
        }
      end
    end
  end
end
