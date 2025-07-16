module Channel
  module Bukopin
    class ElectricityPostpaid
      module Requests
        class Payment < Requests::Base
          attr_reader :payload_object

          # parameter should be ::Channel::Bukopin::Iso::Requests::Inquiry's response
          def initialize(inquiry_response_hash, track_id: nil, buyer_type:)
            @tags = initialize_my_tags
            @inquiry_response_hash = inquiry_response_hash
            @raw_data = inquiry_response_hash[:raw_data]
            @track_id = track_id
            @buyer_type = buyer_type
          end

          def run!
            @result = wrap_request(track_id: @track_id, buyer_type: @buyer_type)
            raise Exceptions::Bukopin::Payment.new(@result&.[](:message)) unless @result.present? && @result[:status] == 'success'

            @result
          end

          private

          def my_parser
            Parsers::PAYMENT_48
          end

          def build_request_message
            message = IsoMessage.new(Mti::PAYMENT, get_config[:partner_central_id], get_config[:user_id])
            message[2] = PRIMARY_ACCOUNT_NUMBER

            amount = @inquiry_response_hash[:amount] + @inquiry_response_hash[:admin_charge]
            message[4] = transaction_amount_format(amount)
            message[11] = @raw_data[11]
            message[26] = MERCHANT_CODE
            message[32] = BANK_CODE
            message[48] = @raw_data[48].dup.insert(20, @inquiry_response_hash[:bill_status]) # insert payment status after bill status
            message[53] = get_token(message[11])
            message[61] = @inquiry_response_hash[:reference_number]
            message
          end

          def transaction_amount_format(amount)
            amount_str = amount.to_s.rjust(12, '0')
            "3600#{amount_str}"
          end
        end
      end
    end
  end
end
