module Quickpays
  class Get
    include QuickpayHelper

    def initialize(remote_type, today, user_id)
      @remote_type = remote_type
      @today = today
      @user_id = user_id
    end

    def run!
      key = quickpays_list_key(@remote_type, @user_id)
      value = RedisOlympus.get(key)

      if value.nil?
        expire_in_end_of_month = ((@today.end_of_month - @today) / 1.seconds).round

        transactions = transaction_klass.where(buyer_id: @user_id, state: 'succeeded')
          .where("succeeded_at > ?", (@today - 3.months).at_beginning_of_month)
          .order(succeeded_at: :desc)

        transactions = transactions.uniq { |t| t.customer_number }
        transactions = transactions.take(15)

        RedisOlympus.set(
          key,
          {transactions: transactions}.to_json,
          ex: expire_in_end_of_month
        )
      else
        transactions_hash = JSON.parse(value).with_indifferent_access
        transactions = transactions_hash[:transactions]
      end

      transactions
    end

    private

    def transaction_klass
      case @remote_type
      when 'bpjs-kesehatan'
        BpjsKesehatanTransaction
      when 'pdam'
        PdamTransaction
      when 'electricity_postpaid'
        PostpaidTransaction
      when 'phone-credit-postpaid'
        PhoneCreditPostpaidTransaction
      else
        raise 'Unsupported type'
      end
    end
  end
end
