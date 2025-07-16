module Channel
  module Pnl
    class CreditCardBill < Base
      include CreditCardBillHelper

      def initialize(object)
        @object = object
        @biller_product = snake_case(object.biller.name)
      end

      def inquiry_to_partner
        response = inquiry(@object.customer_number, @object.biller.id)
        result = ResponseGeneralizer::CreditCardBill.new do |r|
          r.customer_number = @object.customer_number
          r.biller = @object.biller
          r.partner = @object.biller.partner

          r.customer_name = response.dig(:data, :name)
        end

        masking(result, @object.biller.biller_code)
      end

      def create_transaction
        raise 'object must be transaction' unless @object.is_a?(CreditCardBillTransaction)
        response = create(@object)

        result = ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = PROCESS
          r.partner_transaction_id = @object.order_id
        end
      end

      def confirm_transaction
        raise 'object must be transaction' unless @object.is_a?(CreditCardBillTransaction)
        response = confirm(@object)

        result = ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = get_transaction_status(response)
          r.reference_number = response.dig(:data, :transaction, :reference_id)
        end

        if response.dig(:data, :transaction, :rejected_code)&.to_i == 51
          result.status = FAILED
          Observer.counter(Observer::Metric::INSUFFICIENT_CCB_BALANCE, 1, { partner: PNL })
          LogBook.info('Dana Partner DBS Kurang untuk Tagihan Kartu Kredit', %w[channel dbs failed], { response: response }, track_id: @object.remote_transaction_id)
        end

        result
      end

      private

      def get_transaction_status(response)
        case response.dig(:data, :transaction, :status_code)
        when PNL_SUCCESS
          SUCCESS
        # turn off refund
        # when PNL_FAILED
        #   FAILED
        else
          PROCESS
        end
      end

    end
  end
end
