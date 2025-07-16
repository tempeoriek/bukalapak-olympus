require 'iso8583'

# P.S. Some of the methods here can be generalized to a method
module Channel
  module Bukopin
    class ElectricityPostpaid
      class IsoMessage < ISO8583::Message
        include ISO8583
        CCYYMMDDhhmmssCodec = ISO8583._date_codec('%Y%m%d%H%M%S')
        CCYYMMDDCodec = ISO8583._date_codec('%Y%m%d')

        CCYYMMDDhhmmss = Field.new
        CCYYMMDDhhmmss.codec = CCYYMMDDhhmmssCodec
        CCYYMMDDhhmmss.length = 14

        CCYYMMDD = Field.new
        CCYYMMDD.codec = CCYYMMDDCodec
        CCYYMMDD.length = 8

        mti_format AN, length: 4
        mti '2200', 'Acquirer Financial Request'
        mti '2210', 'Issuer Response to Financial Request'
        mti '2100', 'Acquirer Inquiry Request'
        mti '2110', 'Issuer Response to Inquiry Request'
        mti '2220', 'Acquirer Reversal Request Prepaid'
        mti '2221', 'Acquirer Reversal Request Repeat Prepaid'
        mti '2230', 'Acquirer Reversal Response Prepaid'
        mti '2231', 'Acquirer Reversal Response Repeat Prepaid'
        mti '2400', 'Acquirer Reversal Request'
        mti '2401', 'Acquirer Reversal Request Repeat'
        mti '2410', 'Acquirer Reversal Response'
        mti '2411', 'Acquirer Reversal Response Repeat'
        mti '2800', 'Network Management Request'
        mti '2810', 'Network Management Response'

        bmp 2, 'Primary account number (PAN)', LLVAR_N, max: 5
        bmp 4, 'Transaction amount', N, length: 16
        bmp 11, 'STAN', N, length: 12
        bmp 12, 'Local transaction time', CCYYMMDDhhmmss
        bmp 15, 'Settlement date', CCYYMMDD
        bmp 26, 'Merchant Category Code', N, length: 4
        bmp 29, 'Amount, settlement fee', N, length: 9
        bmp 30, 'Amount, transaction processing fee', N, length: 9
        bmp 31, 'Amount, settlement processing fee', N, length: 9
        bmp 32, 'Bank Code', LLVAR_N, max: 7
        bmp 33, 'Partner Central ID', LLVAR_N, max: 7
        bmp 39, 'Response code', AN, length: 4
        bmp 40, 'Action Code', N, length: 3
        bmp 41, 'Terminal ID', ANS, length: 16
        bmp 48, 'Additional data', LLLVAR_ANS, max: 999
        bmp 53, 'Security Data', AN, length: 16
        bmp 56, 'Original Data Element', LLVAR_N, max: 37
        bmp 61, 'Additional data 2', LLLVAR_ANS, max: 45
        bmp 62, 'Additional data 3', LLLVAR_AN, max: 61
        bmp 63, 'Info Text', LLLVAR_ANS, max: 999

        RESPONSE_CODE_MAP = {
          '0000' => 'Berhasil',
          '0008' => 'Invalid Acces Time',
          '0011' => 'Need to sign on first',
          '0012' => 'Cannot reverse because exceed time limit',
          '0013' => 'Jumlah transaksi tidak valid.',
          '0014' => 'Subscriber tidak dikenali.',
          '0016' => 'Konsumen %s diblokir. Hubungi PLN.',
          '0030' => 'Pesan partner tidak valid.',
          '0045' => 'Admin charge tidak valid.',
          '0047' => 'Total KWH melebihi batas maksimum',
          '0063' => 'Unable to reverse because of no payment',
          '0068' => 'Timeout ke PLN',
          '0077' => 'Konsumen %s diblokir. Hubungi PLN.',
          '0088' => 'Tagihan sudah terbayar.',
          '0089' => 'Tagihan saat ini sedang tidak tersedia',
          '0092' => 'Switcher receipt reference number is not available',
          '0093' => 'Invalid switcher reference number',
          '0094' => 'Transaksi Gagal.',
          '0096' => 'Transaction was not found on Legacy System'
        }
        DEFAULT_ERROR_MESSAGE = 'Aduh, sistemnya lagi ada gangguan, kembali lagi nanti ya!'
        REVERSAL_MTIS = Set.new([
          Constants::Mti::REVERSAL,
          Constants::Mti::REVERSAL_REPEAT,
          Constants::Mti::REVERSAL_RESPONSE,
          Constants::Mti::REVERSAL_REPEAT_RESPONSE
        ])
        def initialize(mti = nil, partner_central_id = nil, user_id = nil)
          super(mti)
          self[12] = Time.now.strftime('%Y%m%d%H%M%S')
          self[33] = partner_central_id
          self[41] = user_id.to_s.rjust(16, '0')

          @additional_private_data = {} # bit 48
        end

        def encode
          str_hex = b2hex(_body[0])
          message = mti + str_hex.upcase + _body[1]
          # header_message is included
          header_message = calculate_header_message(message.length)
          header_message + message
        end

        def self.decode(str)
          flag = hex_to_binary(str[4]) # get first digit of bitmap and convert it to binary
          bitmap_digit = flag[0] == '1' ? 32 : 16
          mti = str[0..3]
          bitmap = bitmap_to_byte(str[4..bitmap_digit + 3])
          data_element = str[bitmap_digit + 4..-1] # get until end of string
          IsoMessage.parse(mti + bitmap + data_element)
        end

        def self.bitmap_to_byte(string)
          IsoMessage.new.hex2b(string)
        end

        def self.hex_to_binary(str)
          binary = str.hex.to_s(2)
          # this is because zero in the front is not outputed in ruby
          return binary.rjust(4, '0') if binary.length < 4
          binary
        end

        def to_hash_a
          hash = {}
          @values.sort.to_h.each do |index, field|
            hash[field.bmp.to_s.rjust(3, '0').to_sym] = field.encode
          end
          hash
        end

        def successful?
          self[39] == Constants::ResponseCodes::SUCCESSFUL
        end

        def need_sign_on?
          self[39] == Constants::ResponseCodes::NEED_SIGN_ON
        end

        def invalid_security_data?
          self[39] == Constants::ResponseCodes::INVALID_SECURITY_DATA
        end

        def reversal_exceed_time_limit?
          self[39] == Constants::ResponseCodes::REVERSAL_EXCEED_TIME_LIMIT
        end

        def reversal?
          REVERSAL_MTIS.include?(mti)
        end

        def build_hash_raw_data
          raw_data = Hash.new
          message_fields = JSON.parse(self.to_json)['values']
          message_fields.each do |key, field|
            raw_data[key.to_i] = field['value']
          end
          raw_data
        end

        def build_hash(parser)
          # status is the transaction's status, not the request status
          @additional_private_data = decode_additional_private_data(parser)
          if (successful? && !reversal?) || (reversal? && reversal_exceed_time_limit?)
            build_successful_response
          else
            build_failed_response
          end
        end

        def build_successful_response
          {
            status: ::Postpaid::Constant::BUKOPIN_SUCCESS,
            response_code: self[39],
            customer_number: @additional_private_data[:customer_number],
            customer_name: @additional_private_data[:customer_name],
            segmentation: @additional_private_data[:subscriber_segmentation],
            power: @additional_private_data[:power_consuming_category].to_i,
            stand_meter: @additional_private_data[:stand_meter],
            outstanding_bill: @additional_private_data[:bill_status].to_i,
            unpaid_bill: @additional_private_data[:outstanding_bill].to_i - @additional_private_data[:bill_status].to_i,
            admin_charge: @additional_private_data[:total_admin_charges].to_i,
            # self[4] is integer with the 4 first digit contain information about currency_code and total of decimal digit eg: 3600
            # rupiah currency code 360 and 0 decimal digit
            amount: self[4] % 1000000000000,
            reference_number: @additional_private_data[:reference_number],
            bills: @additional_private_data[:bills],
            bill_status: @additional_private_data[:bill_status],
            info_text: self[63] || '',
            stan: self[11],
            raw_data: build_hash_raw_data
          }
        end

        def build_failed_response
          {
            status: ::Postpaid::Constant::BUKOPIN_FAILED,
            response_code: self[39],
            message: response_code_message,
          }
        end

        def response_code_message
          RESPONSE_CODE_MAP.fetch(self[39], DEFAULT_ERROR_MESSAGE) % @additional_private_data[:customer_number]
        end

        def decode_additional_private_data(parser)
          message = self[48]
          result = {}
          offset = 0
          parser.each do |k, v|
            result[k] = message[offset..offset+v-1]
            offset += v
          end
          counter = result[:bill_status].to_i
          bills = []
          prev_stand_meter = ''
          curr_stand_meter = ''
          while counter > 0
            counter -= 1
            bill = {}
            Constants::Parsers::BILL_DETAILS.each do |k, v|
              bill[k] = message[offset..offset+v-1]
              offset += v
            end
            prev_stand_meter = bill[:previous_meter_reading] if bills.empty?
            curr_stand_meter = bill[:current_meter_reading]
            bill[:penalty_fee] = bill[:penalty_fee].to_i
            bill[:amount] = bill[:total_electricity_bill].to_i
            bill[:previous_meter] = bill[:previous_meter_reading]
            bill[:current_meter] = bill[:current_meter_reading]
            bills << bill
          end
          result[:stand_meter] = "#{prev_stand_meter} - #{curr_stand_meter}"
          result[:bills] = bills
          result
        end

        private

        def calculate_header_message(message_len)
          "#{(message_len / 256).chr}#{(message_len % 256).chr}"
        end
      end
    end
  end
end
