module Channel
  module Visa
    class CreditCardBill < Channel::Visa::Base
      include ApplicationHelper

      def initialize(object)
        @object = object
      end

      def inquiry_to_partner
        token_result = secure_acceptance_token
        result = ResponseGeneralizer::CreditCardBill.new do |r|
          r.customer_number = token_result[:req_card_number].upcase
          r.biller = @object.biller
          r.partner = @object.biller.partner
          r.customer_name = ''
        end
        masking(result, @object.biller.biller_code)
        result.response_code = "#{RC_PREFIX}#{token_result[:reason_code]}"
        result.token = token_result[:payment_token]
        result.card_data = nil
        result
      end

      def create_transaction
        start_time = ::Time.current
        payouts = CyberSource::Payouts.new(token: get_token, amount: base_amount)
        response = payouts.send_request
        validate_payouts_response(response)
        result = ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = SUCCESS # remit trx
          r.reference_number = payouts&.reference_code
          r.response_code = get_rc(response[:processorInformation][:responseCode] || response[:status])
          r.partner_transaction_id = response[:id]
        end
      rescue RestClient::Exceptions::Timeout => e
        result = ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = PROCESS # continue to bg job confirm_transaction
          r.reference_number = payouts&.reference_code
          r.response_code = 'timeout'
        end
      rescue Exceptions::Visa::PayoutsFailed => e
        result = ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = PENDING # trx stuck, need admin to manually action
          r.reference_number = payouts&.reference_code
          r.response_code = response.present? ? get_rc(response[:status]) : nil
        end
      rescue Exceptions::Visa::NoToken => e
        # In rare cases when trx state is stuck at processed and the trx
        # created_at has already passed the designated expiry_time limit,
        # then a rake task olympus:visa:cleanup_token run by cronjob will be
        # executed to clean up token.
        # Thus, the trx will render unprocessable and should be refunded to user.
        result = ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = FAILED # refund trx
          r.reference_number = payouts&.reference_code
          r.response_code = get_rc('NO_TOKEN')
        end
      rescue => e
        raise e # will stuck trx at processed state
      ensure
        log_and_metric(action:        :payout,
                       url:           payouts&.url,
                       payload:       payouts&.payload,
                       result:        result&.attributes,
                       duration:      ::Time.current - start_time,
                       response_code: get_rc(result&.response_code, no_prefix: true),
                       error:         e)
      end

      def delete_token
        return true if @object.token.blank?
        start_time = ::Time.current
        token_deletion = CyberSource::DeleteToken.new(token: @object.token)
        response = token_deletion.send_request
      rescue => e
        # Suppress raising error if token deletion had failed.
        # The undeleted tokens will be cleaned up by rake task olympus:visa:cleanup_token
        response = false
      ensure
        if token_deletion.present?
          status = response == true ? 'success' : 'failed'
          log_and_metric(action:        :delete_token,
                         url:           token_deletion.url(exclude_token: true), # the url contains token in path which we don't want it to be logged anywhere
                         payload:       nil,
                         result:        status,
                         duration:      ::Time.current - start_time,
                         response_code: get_rc(status, no_prefix: true),
                         error:         e)
        end
      end

      def confirm_transaction
        if @object.reference_number.blank?
          result = ResponseGeneralizer::CreditCardBill.new do |r|
            r.status = PENDING
            r.response_code = get_rc('NO_REF_CODE')
          end
        else
          # result = search_transaction
          # result = create_transaction if result[:status] != SUCCESS
          start_time = ::Time.current
          search_trx = CyberSource::SearchTransaction.new(client_reference_information_code: @object.reference_number)
          response = search_trx.send_request
          response = simplify_search_transaction_response(response)

          result = ResponseGeneralizer::CreditCardBill.new do |r|
            r.status = response[:status] # possible value: SUCCESS, PENDING
            r.response_code = get_rc(response[:reason_code]) || 'TRX_NOT_FOUND'
            r.partner_transaction_id = response[:id]
          end
        end
      rescue RestClient::Exceptions::Timeout => e
        result = ResponseGeneralizer::CreditCardBill.new do |r|
          r.status = PENDING
          r.response_code = 'timeout'
        end
      rescue => e
        raise e # catch error object for logging
      ensure
        if search_trx.present?
          log_and_metric(action:        :search_transaction,
                         url:           search_trx&.url,
                         payload:       search_trx&.payload,
                         result:        result&.attributes,
                         duration:      ::Time.current - start_time,
                         response_code: get_rc(result&.response_code, no_prefix: true),
                         error:         e)
        end
      end

      private

      def get_token
        if @object.token.present?
          return @object.token
        else
          raise Exceptions::Visa::NoToken.new
        end
      end

      def get_rc(rc, no_prefix: false)
        # Under a successful request, response[:processorInformation][:responseCode] will always be present.
        # Please check https://developer.cybersource.com/library/documentation/dev_guides/payouts_SO/Payouts_SO_API.pdf Appendix D, E
        # Otherwise, string status response[:status] will be used and will be converted into custom RC number
        # Use prefix VISA_ to distinguish RC from other partner
        if rc.present?
          return rc.gsub(RC_PREFIX, '') if no_prefix
          return "#{RC_PREFIX}#{rc}"
        end
      end

      def validate_payouts_response(response)
        raise Exceptions::Visa::PayoutsFailed.new if response.blank?
        raise Exceptions::Visa::PayoutsFailed.new(response.to_json) unless response[:status] == 'ACCEPTED'
      end

      def simplify_search_transaction_response(response)
        reason_code = nil
        trx_id      = nil
        status      = PENDING
        if response[:_embedded].present? && response[:_embedded][:transactionSummaries].present?
          response[:_embedded][:transactionSummaries].each do |trx|
            reason_code = trx[:applicationInformation][:reasonCode].to_s
            if trx[:clientReferenceInformation][:code] == @object.reference_number && reason_code == RC_ACCEPTED
              trx_id = trx[:id]
              status = SUCCESS
              break
            end
          end
        end
        {
          reason_code: reason_code,
          id: trx_id,
          status: status,
        }
      end

    end
  end
end
