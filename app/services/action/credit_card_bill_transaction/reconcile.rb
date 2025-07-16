module Action
  module CreditCardBillTransaction
    class Reconcile
      include PostpaidTransactionUtility

      ParamObject = Struct.new(:start_date, :end_date, :partner_transaction_id)

      def initialize(start_date, end_date)
        @object = ParamObject.new(start_date, end_date, nil)
        @redis_key = "CCB:#{start_date}:#{end_date}" # e.g. CCB:2019-03-04:2019-03-05
        @list_trx_id = RedisOlympus.smembers(@redis_key) || []
      end

      def run!
        list_trx = partner.get_transaction_list
        list_trx.each do |trx_bni|
          begin
            next if have_been_processed?(trx_bni[:transaksi_id]&.to_s)
            @object.partner_transaction_id = trx_bni[:transaksi_id]

            response = partner.get_transaction_detail
            reffnum = response.reference_number

            transaction = ::CreditCardBillTransaction.find_by_reference_number(response.reference_number)
            raise Exceptions::TransactionNotFound.new unless transaction.present?

            update_transaction(transaction, response)

            RedisOlympus.sadd(@redis_key, trx_bni[:transaksi_id])
          rescue => e
            tags = %W(bni reconcile transaction_detail error)
            opts = {
              backtrace: e.backtrace.take(5)
            }
            log_error(tags, e.message, reffnum, opts)
            next
          end
        end
        200
      end

      private

      def have_been_processed?(id)
        return true if @list_trx_id.include?(id)

        trx = ::CreditCardBillTransaction.find_by_partner_transaction_id(id)
        return false unless trx.present?

        RedisOlympus.sadd(@redis_key, id)
        true
      end

      def partner
        Channel::BNI::CreditCardBill.new(@object)
      end

      def update_transaction(transaction, response)
        ActiveRecord::Base.transaction do
          transaction.lock!

          raise "Invalid state failed but success from partner" if transaction.state == "failed"

          update_transaction_detail(transaction, response)

          return if transaction.state == "succeeded"

          action = update_transaction_status_action_object(transaction, response)
          action.run!

          @list_trx_id << @object.partner_transaction_id
        end   
      end

      def update_transaction_detail(transaction, response)
        transaction.partner_transaction_id = response.partner_transaction_id
        transaction.response_code = response.response_code
        transaction.save!
      end
    end
  end
end
