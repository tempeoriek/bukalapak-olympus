module Channel
  module Bukopin
    class ElectricityPostpaid
      module Requests
        class Reversal < Requests::Base
          include Constants

          # parameter `payment_iso_response` should be ::Channel::Bukopin::Iso::Requests::Payment's response
          def initialize(payment_iso_request_obj, buyer_type:, retry_count: 0, track_id: nil)
            @retry_count = retry_count
            @tags = initialize_my_tags
            @mti = retry_count > 0 ? Mti::REVERSAL_REPEAT : Mti::REVERSAL
            @raw_data = payment_iso_request_obj
            @track_id = track_id
            @buyer_type = buyer_type
          end

          def run!
            @result = wrap_request(track_id: @track_id, buyer_type: @buyer_type)

            @result
          end

          private

          def my_parser
            Parsers::PAYMENT_48
          end

          def build_request_message
            message = IsoMessage.new(@mti, get_config[:partner_central_id], get_config[:user_id])
            bit_12 = @raw_data[12].kind_of?(DateTime) ? @raw_data[12].strftime('%Y%m%d%H%M%S') : @raw_data[12]

            message[2] = PRIMARY_ACCOUNT_NUMBER
            message[4] = @raw_data[4]
            message[11] = @raw_data[11]
            message[26] = MERCHANT_CODE
            message[32] = BANK_CODE
            message[48] = @raw_data[48]
            message[53] = get_token(message[11])
            message[56] = "#{Mti::PAYMENT}#{@raw_data[11].to_s.rjust(12, '0')}#{bit_12}#{BANK_CODE}"
            message
          end
        end
      end
    end
  end
end
