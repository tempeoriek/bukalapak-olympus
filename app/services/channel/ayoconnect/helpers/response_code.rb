module Channel
  module Ayoconnect
    module Helpers
      module ResponseCode
        # Please refer to API Documentation for more details.
        # https://docs.pipe.ayopop.id/#response-codes
        #
        # >> Error Code Ranges
        #
        # 0-99    : Success - The payment is successful.
        # 100-199 : Failed - The payment is failed and balance is refunded to the account.
        # 200-299 : The transaction is processing. Once further updates are available, a callback will be sent to partner API or partner can get further status via Status API.
        # 300     : Inquiry Successful - The inquiry for the product is successful.
        # 301-399 : Inquiry failed - The inquiry for the product is failed.


        # INQUIRY RESPONSE CODES
        INQUIRY_SUCCESS_RESPONSE_CODES = %w[300]
        INQUIRY_FAILED_RESPONSE_CODES  = {
          '112' => ::Exceptions::UnregisteredNumber, # Blocked IDPEL
          '181' => ::Exceptions::TransactionCannotBeDone, # Inquiry service is down
          '184' => ::Exceptions::PartnerIssue, # Product is Offline
          '301' => ::Exceptions::BillExceedLimit, # bill more than three months
          '302' => ::Exceptions::BillAlreadyPaid, # Bill already paid
          '303' => ::Exceptions::BillAlreadyPaid, # Bill not available
          '304' => ::Exceptions::UnregisteredNumber, # Wrong idpel
          '305' => ::Exceptions::InactiveProvider, # Gangguan pada Sistem Provider
          '306' => ::Exceptions::UnregisteredNumber, # Wrong idpel
          '307' => ::Exceptions::UnregisteredNumber, # Wrong idpel
          '308' => ::Exceptions::UnregisteredNumber, # Wrong idpel
          '309' => ::Exceptions::BillAlreadyPaid, # Bill Already Paid
          '310' => ::Exceptions::PartnerIssue, # Cut off
          '311' => ::Exceptions::PartnerIssue, # Product Is currently unavailable
          '312' => ::Exceptions::TransactionCannotBeDone, # Inquiry Is expired
          '313' => ::Exceptions::TransactionCannotBeDone, # Inquiry and payment details not matching
          '314' => ::Exceptions::TransactionCannotBeDone, # Need pay  mandotary bill (Smart Property case)
          '315' => ::Exceptions::BillExceedLimit, # Failed - bill/fine exceed maximum limit
          '316' => ::Exceptions::TransactionCannotBeDone, # Inquiry Switch is Not Present
          '317' => ::Exceptions::PartnerIssue, # Inactive Inquiry Vendor
          '318' => ::Exceptions::TransactionCannotBeDone, # Invalid or Inactive Category
          '319' => ::Exceptions::TransactionCannotBeDone, # Invalid Server
          '320' => ::Exceptions::TransactionCannotBeDone, # must be paid at the provider locket
          '321' => ::Exceptions::TransactionCannotBeDone, # Bad Request
          '322' => ::Exceptions::TransactionCannotBeDone, # Invalid Product Type
          '323' => ::Exceptions::PartnerIssue, # no server list available
          '324' => ::Exceptions::TransactionCannotBeDone, # Last installment. Please visit the branch office.
          '330' => ::Exceptions::MaxInquiryAttemptExceeded, # Transaction repeated within 30 minutes
          '341' => ::Exceptions::TransactionCannotBeDone, # Product not found
          '364' => ::Exceptions::TransactionCannotBeDone, # Error from operator
          '399' => ::Exceptions::TransactionCannotBeDone, # Failed - generic
          '401' => ::Exceptions::TransactionCannotBeDone, # Unauthorised access
          '409' => ::Exceptions::TransactionCannotBeDone # Inquiry is expired
        }

        # List of RCs caused by partner
        # e.g. Service is down, Product is offline, etc
        INQUIRY_PARTNER_FAILED_RESPONSE_CODES = [
          '181', # Inquiry service is down
          '184', # Product is Offline
          '311', # Product Is currently unavailable
          '313', # Inquiry and payment details not matching
          '316', # Inquiry Switch is Not Present
          '317', # Inactive Inquiry Vendor
          '318', # Invalid or Inactive Category
          '319', # Invalid Server
          '322', # Invalid Product Type
          '323', # no server list available
          '399', # Failed - generic
          '401', # Unauthorised access
        ]

        # PAYMENT RESPONSE CODES

        # List of known errors:
        # 100 - Operator Issue
        # 101 - Connectivity Issue
        # 102 - Duplicate Transaction
        # 103 - Wrong IDPEL / Account Number
        # 104 - Invalid Transaction Amount
        # 105 - User Blocked by Biller
        # 106 - Bill - Exceed Maksimum Limit
        # 107 - User Blocked by Biller
        # 108 - Duplicate Transaction,
        # 109 - Cut off
        # 110 - Product is not available - out of stock.
        # 111 - Exceed Maksimum Limit
        # 114 - Payment Amount not Matched
        # 180 - System Error
        # 183 - ref num not available
        # 185 - inquiry Not Available
        # 186 - product not found
        # 198 - Manually Failed
        # 199 - General error
        # 312 - Inquiry id expired
        # 313 - Inquiry id not matched
        # 401 - Unauthorised access
        # 402 - Payment - cancelled by user
        # 403 - Payment - transfer amount not matching
        # 490 - Payment - cancelled by system
        # 495 - Payment - expired by system

        PAYMENT_SUCCESS_RESPONSE_CODES = %w[0 1 2 3 4 99]
        PAYMENT_PENDING_RESPONSE_CODES = %w[299]
        PAYMENT_FAILED_RESPONSE_CODES  = ((100..199).to_a + [312, 313, 401, 402, 403, 490, 495]).map(&:to_s) # Update: RC between this range is considered refund

        # This is meant to exclude failed Payment RCs from giving failed response in the final status of payment.
        # If there are failed Payment RCs that want to be stucked and needs to be reprocessed, fill the RCs in this list.
        PAYMENT_FAILED_EXCLUDED_RC = %w[102 108]

        # CHECK STATUS CODE

        CHECK_STATUS_UNAVAILABLE_RC = '188'

        ### GENERAL METHODS ###

        def get_status_from_response_code(action, response_code)
          case action.to_sym
          when :inquiry
            inquiry_status(response_code)
          when :payment
            payment_status(response_code)
          when :check_status
            check_payment_status(response_code)
          end
        end

        ### INQUIRY RC RELATED METHODS ###

        def inquiry_request_fail?(response_code)
          INQUIRY_FAILED_RESPONSE_CODES.keys.include? response_code.to_s
        end

        def inquiry_request_partner_fail?(response_code)
          response_code.to_s != "" ? INQUIRY_PARTNER_FAILED_RESPONSE_CODES.include?(response_code.to_s) : true
        end

        def raise_inquiry_error!(response_code)
          if inquiry_request_fail?(response_code)
            raise INQUIRY_FAILED_RESPONSE_CODES[response_code.to_s].new
          else
            raise Exceptions::TransactionCannotBeDone.new
          end
        end

        def inquiry_status(response_code)
          return :success if INQUIRY_SUCCESS_RESPONSE_CODES.include? response_code.to_s
          return :failed if INQUIRY_FAILED_RESPONSE_CODES.keys.include? response_code.to_s
          return :error
        end

        ### PAYMENT RC RELATED METHODS ###

        def payment_request_fail?(response_code)
          PAYMENT_FAILED_RESPONSE_CODES.include? response_code.to_s
        end

        def payment_status(response_code)
          return :success if PAYMENT_SUCCESS_RESPONSE_CODES.include? response_code.to_s
          return :pending if (PAYMENT_PENDING_RESPONSE_CODES + PAYMENT_FAILED_EXCLUDED_RC).include? response_code.to_s
          return :failed if PAYMENT_FAILED_RESPONSE_CODES.include? response_code.to_s
          return :error
        end

        ### CHECK STATUS RC RELATED METHODS ###

        # Unexpected RCs and pending RCs will be stuck
        def check_payment_status(response_code)
          return :success if PAYMENT_SUCCESS_RESPONSE_CODES.include? response_code.to_s
          return :failed if (PAYMENT_FAILED_RESPONSE_CODES - PAYMENT_FAILED_EXCLUDED_RC).include?(response_code.to_s)
          return :pending
        end

        def transaction_not_available?(response_code)
          response_code == CHECK_STATUS_UNAVAILABLE_RC
        end
      end
    end
  end
end
