module Channel
  module Thor
    module Helpers
      module ResponseCode

        SUCCESS_RC = %w[0000]
        FAILED_RC = {
          '0004' => ::Exceptions::Thor::Unauthorized, # unauthenticated
          '0005' => ::Exceptions::Thor::DefaultError, #  other error
          '0008' => ::Exceptions::TransactionCannotBeDone, # invalid access time
          '0009' => ::Exceptions::TransactionCannotBeDone, # inactive user
          '0013' => ::Exceptions::TransactionCannotBeDone, # invalid transaction amount
          '0014' => ::Exceptions::UnregisteredNumber, # unknown customer id
          '0015' => ::Exceptions::UnregisteredNumber, # unknown meter number
          '0017' => ::Exceptions::TransactionCannotBeDone, # customer has outstanding bills
          '0030' => ::Exceptions::Thor::DefaultError, # invalid message
          '0033' => ::Exceptions::TransactionCannotBeDone, # unknown product
          '0035' => ::Exceptions::UnregisteredNumber, # unregistered user
          '0036' => ::Exceptions::Thor::DefaultError, # duplicate order id
          '0041' => ::Exceptions::Thor::DefaultError, # transaction amount below minimum purchase amount
          '0042' => ::Exceptions::Thor::DefaultError, # transaction amount above maximum purchase amount
          '0043' => ::Exceptions::Thor::DefaultError, # new power category is smaller
          '0044' => ::Exceptions::Thor::DefaultError, # new power category is not valid
          '0045' => ::Exceptions::Thor::DefaultError, # invalid admin amount
          '0046' => ::Exceptions::Thor::DefaultError, # insufficient balance
          '0047' => ::Exceptions::BillExceedLimit, # total KWH is over the limit
          '0048' => ::Exceptions::TransactionCannotBeDone, # request is expired
          '0063' => ::Exceptions::TransactionCannotBeDone, # no payment
          '0068' => ::Exceptions::Thor::DefaultError, # timeout
          '0077' => ::Exceptions::AccountSuspended, # customer suspended
          '0083' => ::Exceptions::Thor::PdamBillCanOnlyBePaidDirectly, # PDAM bills can only be paid directly
          '0088' => ::Exceptions::BillAlreadyPaid, # bills are already paid
          '0089' => ::Exceptions::BillAlreadyPaid, # current bill is not available
          '0090' => ::Exceptions::Thor::CutOff, # cut off
          '0091' => ::Exceptions::Thor::DefaultError, # database error
          '0092' => ::Exceptions::PartnerTransactionNotFound, # order id is not found
          '0094' => ::Exceptions::TransactionCannotBeDone, # reversal has been done
          '0098' => ::Exceptions::Thor::DefaultError, # reference number is not valid
        }
        PARTNER_FAILED_RC = [
          '0004', # unauthenticated
          '0005', # other error
          '0008', # invalid access time
          '0030', # invalid message
          '0033', # unknown product
          '0046', # insufficient balance
          '0063', # no payment
          '0068', # timeout
          '0090', # cut off
          '0091', # database error
          '0098', # reference number is not valid
          '0100', # unknown error
        ]

        TRANSACTION_PENDING_RC = %w[0063 0068 0100]
        TRANSACTION_FAILED_RC = FAILED_RC.except(*TRANSACTION_PENDING_RC)

        TRANSACTION_UNAVAILABLE_RC = %w[0092]
        ADVICE_PENDING_RC = %w[0083 0090]

        def get_status_from_response_code(action, response_code)
          case action.to_sym
          when :inquiry
            inquiry_status(response_code)
          when :create_transaction
            create_transaction_status(response_code)
          when :get_transaction_by_id
            get_transaction_by_id_status(response_code)
          end
        end

        def failed_response?(response_code)
          FAILED_RC.include?(response_code.to_s)
        end

        def partner_failed_response?(response_code)
          !FAILED_RC.include?(response_code.to_s) || PARTNER_FAILED_RC.include?(response_code.to_s)
        end

        def raise_failed_inquiry!(response_code, product = nil, message = nil)
          err = FAILED_RC[response_code.to_s]

          raise Exceptions::TransactionCannotBeDone.new if err.nil?

          if product != 'pdam' && err == Exceptions::Thor::PdamBillCanOnlyBePaidDirectly
            raise Exceptions::Thor::DefaultError.new(message) if message.present?
            raise Exceptions::Thor::DefaultError.new
          end

          if is_electricity_postpaid_inquiry_custom_message(product, err)
            raise err.new(message) if message.present?
          end

          if err == ::Exceptions::Thor::DefaultError
            raise err.new(message) if message.present?
            raise err.new
          else
            raise FAILED_RC[response_code.to_s].new
          end
        end

        def inquiry_status(response_code)
          return :success if SUCCESS_RC.include? response_code.to_s
          return :failed if FAILED_RC.keys.include? response_code.to_s
          return :error
        end

        def create_transaction_status(response_code)
          return :success if SUCCESS_RC.include? response_code.to_s
          return :pending if TRANSACTION_PENDING_RC.include? response_code.to_s
          return :failed if TRANSACTION_FAILED_RC.include? response_code.to_s
          return :error
        end

        def get_transaction_by_id_status(response_code)
          return :success if SUCCESS_RC.include? response_code.to_s
          return :pending if (TRANSACTION_PENDING_RC + ADVICE_PENDING_RC).include? response_code.to_s
          return :failed if TRANSACTION_FAILED_RC.except(*TRANSACTION_UNAVAILABLE_RC, *ADVICE_PENDING_RC).include? response_code.to_s
          return :error
        end

        private 

        def is_electricity_postpaid_inquiry_custom_message(product, err)
          inquiry_error = [
            ::Exceptions::UnregisteredNumber,
            ::Exceptions::AccountSuspended,
            ::Exceptions::BillAlreadyPaid,
            ::Exceptions::Thor::CutOff
          ]
          return product == 'electricity_postpaid' && inquiry_error.include?(err)
        end
      end
    end
  end
end
