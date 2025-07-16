# frozen_string_literal: true

module Channel
  module Ayoconnect
    module Helpers
      module ResponseNormalizer
        module BpjsKetenagakerjaan
          include ::Channel::Ayoconnect::Helpers::ResponseNormalizer::Base

          # Constant contains key from Ayoconnect responses
          BILL_AMOUNT = 'Total Iuran'
          BILL_JHT    = 'Iuran JHT'
          BILL_JKK    = 'Iuran JKK'
          BILL_JKM    = 'Iuran JKM'

          # This is not a typo.
          # It is intentional as Ayoconnect is still using JPK,
          # while the official term used by BPJS is JKP (Jaminan Kehilangan Pekerjaan).
          BILL_JKP = 'Iuran JPK'
          BILL_JP  = 'Iuran JPN'

          REFERENCE_NUMBER        = 'Nomor Referensi'
          NPP                     = 'NPP'
          DIVISION                = 'Divisi'
          BRANCH_NAME             = 'Kantor Cabang'
          BILL_CODE               = 'Kode Iuran'
          BPU_START_BILL_PERIOD   = 'Tanggal Efektif Masa Perlindungan'
          BPU_END_BILL_PERIOD     = 'Tanggal Berakhir Masa Perlindungan'
          PU_BILL_MONTH           = 'Bulan Tagihan'

          UNPAID_BILL_TEXT = 'Tunggakan'

          def fetch_customer_info(response, bpjs_tk_type)
            bill_details    = extract_bill_details(response[:data][:billDetails])
            product_details = extract_details(response[:data][:productDetails])
            bills           = build_bills(bill_details)
            extra_fields    = extract_details(response[:data][:extraFields])

            if bpjs_tk_type == :bpu
              start_bill_period = parse_bpu_period(product_details.dig(BPU_START_BILL_PERIOD).to_s)
              end_bill_period = parse_bpu_period(product_details.dig(BPU_END_BILL_PERIOD).to_s)
            elsif bpjs_tk_type == :pu
              start_bill_period = parse_pu_period(product_details.dig(PU_BILL_MONTH).to_s)
              end_bill_period = start_bill_period.end_of_month
            end

            {
              customer_name: response[:data][:customerName],
              customer_number: response[:data][:accountNumber],
              amount: bills.sum { |x| x.dig(:amount) },
              admin_charge: response[:data][:totalAdmin],
              start_bill_period: start_bill_period,
              end_bill_period: end_bill_period,
              npp: product_details.dig(NPP),
              division: product_details.dig(DIVISION),
              branch_name: product_details.dig(BRANCH_NAME),
              bill_code: product_details.dig(BILL_CODE),
              reference_number: product_details.dig(REFERENCE_NUMBER),
              bills: bills,
              unpaid_bills: unpaid_bills?(product_details.dig(BILL_CODE)),
              unpaid_bills_text: extra_fields.dig(UNPAID_BILL_TEXT)
            }.compact
          end

          private

          def extract_bill_details(bills)
            extracted_bills = []

            bills.each do |bill|
              next unless bill[:billId] != '0' # 0 is for admin fee

              extracted_bill = extract_details(bill[:billInfo])

              # parse total iuran
              key = bill[:key]
              value = bill[:value]
              extracted_bill[key] = value

              extracted_bill[:jht] = extracted_bill.dig(BILL_JHT)
              extracted_bill[:jkk] = extracted_bill.dig(BILL_JKK)
              extracted_bill[:jkm] = extracted_bill.dig(BILL_JKM)
              extracted_bill[:jkp] = extracted_bill.dig(BILL_JKP)
              extracted_bill[:jp] = extracted_bill.dig(BILL_JP)

              extracted_bill.compact!

              extracted_bills << extracted_bill
            end

            extracted_bills
          end

          def build_bills(bills)
            bills.map do |bill|
              {
                jht: bill[:jht]&.to_i,
                jkk: bill[:jkk]&.to_i,
                jkm: bill[:jkm]&.to_i,
                jkp: bill[:jkp]&.to_i,
                jp: bill[:jp]&.to_i,
                amount: bill[BILL_AMOUNT]&.to_i
              }.compact
            end
          end

          def parse_pu_period(original_date_string)
            return nil unless original_date_string

            date = Date.strptime(original_date_string, '%m/%Y')
            date.beginning_of_month
          end

          def parse_bpu_period(original_date_string)
            return nil unless original_date_string

            Date.strptime(original_date_string, '%d-%m-%Y')
          end

          def unpaid_bills?(bill_code)
            bill_code != 'N/A' && bill_code.present?
          end
        end
      end
    end
  end
end
