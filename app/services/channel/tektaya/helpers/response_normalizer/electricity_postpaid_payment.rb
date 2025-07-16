# frozen_string_literal: true

module Channel
  module Tektaya
    module Helpers
      module ResponseNormalizer
        module ElectricityPostpaidPayment
          # Extract message from payment response.
          #
          # Example:
          # "01|1|512110000003|DU''MMY-4DEFWWC8WI|I2|000000450|0|79538|NO REF : 1TKT2121AF1EE8C1354BDBAFD6A0DB5A|~Informasi Hubungi Call Center 123~Atau Hub PLN Terdekat : |MEI21|00008888|00008899|79538|10000|79538"
          #
          # The payment response have the format as follows:
          #
          # (Index) - (Field Explanation)
          # 0 - Total outstanding
          # 1 - Bill status
          # 2 - Idpel
          # 3 - Nama
          # 4 - Segmen pelanggan
          # 5 - Daya
          # 6 - Biaya admin bank
          # 7 - Total tagihan
          # 8 - No Reff
          # 9 - Info
          # 10 - Bulan Tahun Periode bayar
          # 11 - Stand Awal
          # 12 - Stand Akhir
          # 13 - Tagihan perbulan
          # 14 - Insentif
          # 15 - Tagihan + denda
          #
          # For multi bill case, it's repeating from index 10 to 15 per bill.
          # 
          def fetch_payment_info(response)
            transaction_id  = response.dig('tty', 'trxid')
            message         = response.dig('tty', 'message')

            extract_payment_info(transaction_id, message)
          end

          private

          def extract_payment_info(transaction_id, message)
            {
              partner_transaction_id: transaction_id,
              reference_number: extract_reference_number(message),
              info_text: extract_info_text(message)
            }
          end

          def extract_reference_number(message)
            match = message.match(/NO REF\s*:\s*(\w+)/i)
            match[1] if match
          end

          # Info text is available at 9th index
          def extract_info_text(message)
            message.split('|')[9]
          end
        end
      end
    end
  end
end
