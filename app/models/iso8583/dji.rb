# frozen_string_literal: true

require 'iso8583'

module Iso8583
  class Dji < ISO8583::Message
    include ISO8583

    ACQUIRER = 'DJI'
    TRACK_ID = 'bukalapak'
    TERMINAL_ID = 1
    IDENTIFICATION_CODE = 'DJI000342'
    MESSSAGE_VERSION = '001'
    UNIQUE_NUMBER_KEY = 'dji:unique_number'

    mti_format AN, length: 4
    mti '0200', 'Acquirer Financial Request'
    mti '0210', 'Issuer Response to Financial Request'
    mti '0800', 'Network Management Request'
    mti '0810', 'Network Management Response'

    # all fields required by DJI
    bmp 3, 'Processing code', N, length: 6
    bmp 4, 'Transaction amount', N, length: 12
    bmp 7, 'Transmission date & time', MMDDhhmmss
    bmp 11, 'STAN', N, length: 6
    bmp 12, 'Local transaction time', Hhmmss
    bmp 13, 'Local transaction date', MMDD
    bmp 18, 'Merchant type', N, length: 4
    bmp 32, 'Acquiring institution', LLVAR_AN, max: 11
    bmp 35, 'Track 2 data', LLVAR_AN, max: 37
    bmp 37, 'Retrieval reference number', N, length: 12
    bmp 39, 'Response code', AN, length: 2
    bmp 41, 'Card acceptor terminal identification', N, length: 8
    bmp 42, 'Card acceptor identification code', AN, length: 15
    bmp 43, 'Card acceptor name/location', ANS, length: 40
    bmp 48, 'Additional data', LLLVAR_ANS, max: 999
    bmp 49, 'Transaction currency code', N, length: 3
    bmp 61, 'Reserved private', LLLVAR_ANS, max: 999
    bmp 62, 'Reserved private', LLLVAR_ANS, max: 999
    bmp 70, 'Network Management Information Code', N, length: 3
    bmp 120, 'Reserved private', LLLVAR_ANS, max: 999
    bmp 127, 'Reserved for private use', LLLVAR_ANS, max: 999

    class << self
      def decode(str)
        flag = hex_to_binary(str[4]) # get first digit of bitmap and convert it to binary
        bitmap_digit = flag[0] == '1' ? 32 : 16
        mti = str[0..3]
        bitmap = bitmap_to_byte(str[4..bitmap_digit + 3])
        data_element = str[bitmap_digit + 4..-1] # get until end of string
        parse(mti + bitmap + data_element)
      end

      private

      def bitmap_to_byte(string)
        Iso8583::Dji.new.hex2b(string)
      end

      def hex_to_binary(str)
        str.hex.to_s(2).rjust(4, '0')
      end
    end

    def initialize(mti = nil)
      super(mti)
      uniq_number = Keystore.increment(UNIQUE_NUMBER_KEY)
      self[7] = Time.now.getlocal('+07:00')
      self[11] = uniq_number % 1000000
      self[12] = Time.now.getlocal('+07:00')
      self[13] = Time.now.getlocal('+07:00')
      self[32] = ACQUIRER
      self[35] = TRACK_ID
      self[41] = TERMINAL_ID
      self[42] = IDENTIFICATION_CODE
      self[127] = MESSSAGE_VERSION
    end

    def encode
      str_hex = self.b2hex(self._body[0])
      message = self.mti + str_hex.upcase + self._body[1]
      #header_message is included
      header_message = calculate_header_message(message.length+2)
      return header_message + message
    end

    def to_hash
      hash = {}
      @values.sort.to_h.each do | _, field |
        hash[field.bmp.to_s.rjust(3, '0').to_sym] = field.encode
      end
      hash
    end

    private

    def calculate_header_message(message_len)
      "#{(message_len / 256).chr}#{(message_len % 256).chr}"
    end
  end
end
