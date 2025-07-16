module Channel
  module Bukopin
    class ElectricityPostpaid
      module Requests
        class Network < Requests::Base
          include Constants

          def initialize(network_action_code, buyer_type)
            @network_action_code = network_action_code
            @tags = initialize_my_tags
            @description = NetworkCodes::DESCRIPTION[network_action_code]
            @tags << @description
            @buyer_type = buyer_type
          end

          def run!
            @result = wrap_request(log_excluding_keys: %i[raw_payload raw_response response], max_retry_count: 0, buyer_type: @buyer_type) do |decoded_response|
              build_response_hash(decoded_response)
            end

            raise Exceptions::Bukopin::Network.new(@result[:message]) unless @result[39] == '0000'

            @result
          end

          private

          def my_parser
            nil
          end

          def initialize_my_tags
            my_tags = super()
            my_tags << @description
            my_tags
          end

          def build_request_message
            message = IsoMessage.new(Mti::NETWORK, get_config[:partner_central_id], get_config[:user_id])
            message[40] = @network_action_code
            message[48] = SWITCHER_ID
            message
          end

          def build_response_hash(decoded_response)
            {
              12 => decoded_response[12],
              33 => decoded_response[33],
              39 => decoded_response[39],
              40 => decoded_response[40],
              41 => decoded_response[41],
              48 => decoded_response[48]
            }
          end
        end
      end
    end
  end
end
