module Channel
    module Thor
      class CreditCardBill < ::Channel::Thor::Base
        PRODUCT_TYPE           = 'credit_card_bill'.freeze
        CREATE_TRANSACTION_URL = '/v1/transactions/cc-bills'.freeze
        CONFIRM_URL            = '/v1/transactions/cc-bills/order-id/'.freeze

        THOR_RESPONSE_TRANSACTION_KEY = 'credit_card_bill_transaction'.freeze

        def initialize(object)
          @object = object
          @product_type = PRODUCT_TYPE
        end

        def create_transaction
          payload = {
            card_number: @object.customer_number,
            account_number: nil,
            order_id: @object.order_id.to_s,
            product_code: @object.biller.partner.biller_code,
            amount: @object.amount.to_s
          }

          response = create(payload)

          build_transaction_response(response)
        end

        def confirm_transaction
          response = get_transaction_by_id(@object.order_id.to_s)

          build_transaction_response(response)
        end

        def product_type
          PRODUCT_TYPE
        end

        private

        def build_transaction_response(response)
            result = ResponseGeneralizer::CreditCardBill.new do |r|
                r.status = response[:status]
                r.customer_name = response[:customer_name]&.strip
                r.customer_number = response[:card_number]
                r.statement_date = response[:statement_date]
                r.due_date = response[:due_date]
                r.amount = response[:amount]
                r.minimum_payment = response[:minimum_payment]
                r.reference_number = response[:reference_number]
                r.partner_financial_journal_number = response[:financial_journal_number]
                r.partner_transaction_id = response[:order_id]
                r.partner_journal_number = response[:journal_number]
                r.response_code = response[:response_code]
            end
        end
      end
    end
end
