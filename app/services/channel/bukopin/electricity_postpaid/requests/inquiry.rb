module Channel
  module Bukopin
    class ElectricityPostpaid
      module Requests
        class Inquiry < Requests::Base
          include Constants

          ERROR_CODE_MAP = {
            '0014' => ::Exceptions::UnregisteredNumber,
            '0016' => ::Exceptions::AccountSuspended,
            '0077' => ::Exceptions::AccountSuspended,
            '0088' => ::Exceptions::BillAlreadyPaid,
            '0089' => ::Exceptions::BillAlreadyPaid
          }

          def initialize(customer_number, track_id: nil, read_timeout: DEFAULT_INQUIRY_TIMEOUT, buyer_type: nil)
            @tags = initialize_my_tags
            @customer_number = customer_number
            @track_id = track_id
            @read_timeout = read_timeout
            @buyer_type = buyer_type
          end

          # TO DO: Rescue when timeout
          def run!
            @result = wrap_request(read_timeout: @read_timeout, track_id: @track_id, buyer_type: @buyer_type)

            if @result[:status] == 'failed'
              raise ERROR_CODE_MAP[@result[:response_code]].new unless ERROR_CODE_MAP[@result[:response_code]].nil?
              raise Exceptions::Bukopin::Inquiry.new(@result[:message])
            end

            @result
          end

          private

          def my_parser
            Parsers::INQUIRY_48
          end

          def build_request_message
            message = IsoMessage.new(Mti::INQUIRY, get_config[:partner_central_id], get_config[:user_id])
            message[2] = PRIMARY_ACCOUNT_NUMBER
            message[11] = Keystore.increment(get_config[:unique_number_key])
            message[26] = MERCHANT_CODE
            message[32] = BANK_CODE
            message[48] = "#{SWITCHER_ID}#{@customer_number}"
            message[53] = get_token(message[11])
            message
          end

        end
      end
    end
  end
end
