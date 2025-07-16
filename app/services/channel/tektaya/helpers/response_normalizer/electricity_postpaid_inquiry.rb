# frozen_string_literal: true

module Channel
  module Tektaya
    module Helpers
      module ResponseNormalizer
        module ElectricityPostpaidInquiry
          # Extract message and map it to their respective fields. The data in the message is separated with '|'.
          #
          # Example for single bill:
          # 1|1|01|38B319212DE441B0B1E0000000000000|DU''MMY-4DEFWWC8WIJH6|53211| |I2|000000450|000000000|202105|20052021|00000000|000000079538|C|0000010000|0000000000|000000000000|00008888|00008899|00000000|00000000|00000000|00000000
          #
          # Example for multi bill:
          # 4|4|05|E8A41BB694744C808EE0000000000000|DU''MMY-71SUFJPC73K9B|53251|               |R1  |000000450|000000000|202012|20122020|00000000|000000053952|C|0000010000|0000000000|000000009000|00008888|00008899|00000000|00000000|00000000|00000000|202101|20012021|00000000|000000069350|C|0000010000|0000000000|000000009000|00008899|00008910|00000000|00000000|00000000|00000000|202102|20022021|00000000|000000073925|C|0000010000|0000000000|000000009000|00008910|00008921|00000000|00000000|00000000|00000000|202103|20032021|00000000|000000053713|C|0000010000|0000000000|000000006000|00008921|00008932|00000000|00000000|00000000|00000000
          #
          # Explanation of the fields:
          # (Starting with index 0, we take an example of single bill)
          # 
          # (Index) - (Field)
          # 0 - JUMLAH BILL
          # 1 - JUMLAH BILL
          # 2 - TOTAL BILL
          # 3 - REF SW
          # 4 - NAMA
          # 5 - KODE UPJ
          # 6 - TELP UPJ
          # 7 - SEGMEN PELANGGAN
          # 8 - DAYA
          # 9 - TOTAL ADMIN
          # 10 - BULAN TAHUN
          # 11 - TGL JATUH TEMPO
          # 12 - TGL BACA METERAN
          # 13 - TAGIHAN
          # 14 - KODE INSENTIF
          # 15 - INSENTIF
          # 16 - PAJAK
          # 17 - DENDA
          # 18 - STAND AWAL
          # 19 - STAND AKHIR
          # 20 - WBP AWAL
          # 21 - WBP AKHIR
          # 22 - KVARH AWAL
          # 23 - KVARH AKHIR
          #
          # For multi bill case, the bill is repeating from index 10 through 23 and appended by '|'. So for n-bill months, it will be index 10-23, 24-37, 38-53, and so on.

          # For each bills, the length is differ by 14.
          BILL_INDEX_MULTIPLIERS = 14

          # The starting index for the bill
          BILL_MIN_INDEX         = 10

          # Used to format stand meter
          STAND_METER_FORMATTER = '%08d'

          def fetch_inquiry_info(response)
            customer_number = response.dig('tty', 'idpel')
            raw_message     = response.dig('tty', 'message2')
            raise ::Exceptions::PartnerIssue('Cannot load Tektaya message') unless customer_number.present? && raw_message.present?

            customer_number_info = { customer_number: customer_number }
            message              = raw_message.split('|')

            basic_info      = extract_basic_info(message)
            bill_info       = extract_bill_details(message)
            additional_info = extract_additional_info_from_bills(bill_info)
            
            customer_number_info.merge(basic_info).merge(additional_info)
          end

          private

          def extract_basic_info(message)
            {
              outstanding_bill: message[0]&.to_i,
              unpaid_bill: message[0]&.to_i,
              customer_name: message[4]&.strip,
              segmentation: message[7]&.strip,
              power: message[8]&.to_i,
              admin_charge: message[9]&.to_i
            }
          end

          def extract_bill_details(message)
            extracted_bills        = []

            bill_left_index        = BILL_MIN_INDEX
            index_multipliers      = 0

            while message[bill_left_index].present?
              bill                  = {}
              bill[:bill_period]    = ::Converter::StringToDate.convert(message[multiply_index(10, index_multipliers)], string_format: Postpaid::Constant::YYYYMM)
              bill[:bill_due_date]  = ::Converter::StringToDate.convert(message[multiply_index(11, index_multipliers)], string_format: Postpaid::Constant::DDMMYYYY)
              bill[:amount]         = message[multiply_index(13, index_multipliers)].to_i
              bill[:penalty_fee]    = message[multiply_index(17, index_multipliers)].to_i
              bill[:previous_meter] = STAND_METER_FORMATTER % message[multiply_index(18, index_multipliers)].to_i
              bill[:current_meter]  = STAND_METER_FORMATTER % message[multiply_index(19, index_multipliers)].to_i

              extracted_bills << bill

              index_multipliers += 1
              bill_left_index = multiply_index(BILL_MIN_INDEX, index_multipliers)
            end

            extracted_bills
          end

          def extract_additional_info_from_bills(bill_info)
            {
              stand_meter: summarize_stand_meter(bill_info),
              amount: bill_info.sum { |bill| bill[:amount] },
              penalty_fee: bill_info.sum { |bill| bill[:penalty_fee] },
              bills: bill_info
            }
          end

          def summarize_stand_meter(bill_info)
            previous_meter = bill_info.first[:previous_meter]
            current_meter  = bill_info.last[:current_meter]
            "#{previous_meter} - #{current_meter}"
          end

          def multiply_index(index, multipliers)
            index + (multipliers * BILL_INDEX_MULTIPLIERS)
          end
        end
      end
    end
  end
end
