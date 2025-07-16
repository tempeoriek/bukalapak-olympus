module Quickpays
  class Delete
    include QuickpayHelper

    def initialize(remote_type, today, user_id, payload)
      @remote_type = remote_type
      @today = today
      @user_id = user_id
      @payload = payload
    end

    def run!
      begin
        key = quickpays_list_key(@remote_type, @user_id)
        value = RedisOlympus.get(key)

        if value
          transactions_hash = JSON.parse(value).with_indifferent_access
          transactions = transactions_hash[:transactions]

          transactions = transactions.delete_if do |transaction|
            transaction[:customer_number] == @payload[:customer_number]
          end

          RedisOlympus.set(key, {transactions: transactions}.to_json, ex: until_end_of_month(@today))
        end

        operator_or_biller = @payload[:operator] || @payload[:biller]
        id = operator_or_biller.nil? ? nil : operator_or_biller[:id]

        key = customer_number_key(@remote_type, @today, @payload[:customer_number], id)
        RedisOlympus.del(key)
      rescue
      end
    end
  end
end
