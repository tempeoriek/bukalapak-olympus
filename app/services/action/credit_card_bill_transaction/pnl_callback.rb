module Action
  module CreditCardBillTransaction
    class PnlCallback
      include PostpaidTransactionUtility
      include CachePartnerResponseUtility

      ALERT_BOT_URL = "https://tukubot.herokuapp.com:443/notify-dbs/insufficient-fund".freeze
      ALERT_BOT_HOST = "tukubot.herokuapp.com:443".freeze
      DEFAULT_IMAGE_URL = "https://s2.bukalapak.com/images/desktop/aset-brand/section1-3.png"
      DEFAULT_TERMS_AND_CONDITIONS = "<ol><li>Pastikan kamu sudah mengetahui jumlah tagihan dan min. pembayaran untuk tagihan kartu kreditmu.</li><li>Biaya admin akan ditambahkan pada tagihan di bulan berikutnya.</li></ol>"

      def initialize(callback)
        @callback = callback
      end

      def run!
        order_id = @callback[:payment_id]
        remote_transaction_id = order_id.delete("#{CREDIT_CARD_BILL_PREFIX}-").to_i
        transaction = ::CreditCardBillTransaction.find_by_remote_transaction_id(remote_transaction_id)
        raise ::Exceptions::TransactionNotFound.new if transaction.nil?

        result = ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = PARTNER_STATUS[PNL][@callback.dig(:status, :status)]
          r.reference_number = @callback[:reference_id]
        end

        # ALert when receive Insufficient Funds error
        if insufficient_fund?
          result.status = FAILED
          Observer.counter(Observer::Metric::INSUFFICIENT_CCB_BALANCE, 1, { partner: PNL })
          LogBook.info('Dana Partner DBS Kurang untuk Tagihan Kartu Kredit', %w[pnl_callback insufficient_balance], { payload: @callback }, track_id: remote_transaction_id)
        end

        cache_rc(transaction)
        # TODO: update the trx if needed

        # update the trx status, return the trx
        Action::CreditCardBillTransaction::UpdateStatus.new(transaction, result).run!
      end

      private

      def insufficient_fund?
        status = @callback.dig(:status, :status)
        description = @callback.dig(:status, :description)
        status == PNL_FAILED && description.include?("Insufficient Funds")
      end

      def alert_insufficient_fund
        header = {
          host: ALERT_BOT_HOST
        }
        Channel::Connection::Http.get(ALERT_BOT_URL, nil, nil, header)
      end

      def cache_rc(transaction)
        response_code = @callback.dig(:status, :status) || "unknown_response"
        action_name = "callback"
        cache_partner_response(transaction.product_type, action_name, transaction.partner_name, transaction.remote_transaction_id, response_code)
      end
    end
  end
end
