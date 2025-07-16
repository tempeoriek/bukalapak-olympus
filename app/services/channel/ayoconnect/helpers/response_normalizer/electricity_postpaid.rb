# frozen_string_literal: true
module Channel
  module Ayoconnect
    module Helpers
      module ResponseNormalizer
        module ElectricityPostpaid
          include ::Channel::Ayoconnect::Helpers::ResponseNormalizer::Base

          # Constant contains key from Ayoconnect responses
          CUSTOMER_NAME   = 'Nama Pelanggan'
          CUSTOMER_NUMBER = 'Nomor Pelanggan'

          BILL_TOTAL_BILL_AMOUNT     = 'Jumlah Tagihan'
          BILL_ADMIN_CHARGE          = 'Biaya Administrasi'
          BILL_PENALTY_FEE           = 'Denda'
          BILL_AMOUNT_PER_MONTH      = 'Total Tag PLN Per Bulan'
          BILL_PERIOD_MONTH          = 'Total LBR Tagihan'
          BILL_STAND_METER           = 'Stand Meter'
          BILL_DUE_DATE              = 'Jatuh Tempo'
          BILL_MONTH                 = 'Bulan'
          BILL_AMOUNT                = 'Rp Tag PLN'

          PRODUCT_SEGMENTATION_AND_POWER = 'Total Tarif/Daya'
          PRODUCT_STAND_METER   = 'Stand Meter'
          PRODUCT_PERIOD        = 'BL/TH'

          STAND_METER_FORMATTER = '%08d'

          def fetch_customer_info(response)
            customer_details    = extract_details(response[:data][:customerDetails])
            product_details     = extract_details(response[:data][:productDetails])
            bill_details        = extract_bill_details(response[:data][:billDetails])
            segmentation, power = product_details.dig(PRODUCT_SEGMENTATION_AND_POWER)&.split('/')
            bill_periods        = product_details.dig(PRODUCT_PERIOD)&.split(',') || []

            bills = build_bills(bill_details)

            {
              customer_name: customer_details.dig(CUSTOMER_NAME),
              customer_number: customer_details.dig(CUSTOMER_NUMBER),
              segmentation: segmentation,
              power: remove_alphabetical(power),
              stand_meter: summarize_stand_meter(product_details.dig(PRODUCT_STAND_METER)),
              outstanding_bill: product_details.dig(BILL_PERIOD_MONTH),
              unpaid_bill: product_details.dig(BILL_PERIOD_MONTH),
              amount: bill_details.sum { |x| x.dig(BILL_TOTAL_BILL_AMOUNT).to_i },
              admin_charge: response[:data][:totalAdmin],
              penalty_fee: bill_details.sum { |x| x.dig(BILL_PENALTY_FEE).to_i },
              bills: bills
            }
          end

          private

          def extract_bill_details(bills)
            extracted_bills = []

            bills.each do |bill|
              if bill[:billId] != '0'
                extracted_bill = extract_details(bill[:billInfo])

                # parsed jumlah tagihan
                key = bill[:key]
                value = bill[:value]
                extracted_bill[key] = value

                stand_meter = extracted_bill.dig(BILL_STAND_METER).split('-')
                extracted_bill[:start_stand_meter] = stand_meter.first
                extracted_bill[:end_stand_meter] = stand_meter.last

                extracted_bills << extracted_bill
              end
            end

            extracted_bills
          end

          def build_bills(bills)
            bills.map do |bill|
              bill_month = bill.dig(BILL_MONTH).delete(' ')
              bill_month_format = get_date_format(bill_month)
              {
                bill_period: ::Converter::StringToDate.convert(bill.dig(BILL_MONTH).delete(' '), string_format: bill_month_format),
                due_date: ::Converter::StringToDate.convert(bill.dig(BILL_DUE_DATE), string_format: Postpaid::Constant::DDMMMYYYY),
                penalty_fee: bill.dig(BILL_PENALTY_FEE).to_i,
                amount: bill.dig(BILL_AMOUNT).to_i,
                previous_meter: STAND_METER_FORMATTER % (bill[:start_stand_meter].to_i),
                current_meter: STAND_METER_FORMATTER % (bill[:end_stand_meter].to_i)
              }
            end
          end

          def summarize_stand_meter(stand_meter)
            all = stand_meter.delete(' ').split(',')
            first_stand_meter = STAND_METER_FORMATTER % (all[0].split('-').first.to_i)
            last_stand_meter  = STAND_METER_FORMATTER % (all[-1].split('-').last.to_i)

            "#{first_stand_meter} - #{last_stand_meter}"
          end

          def remove_alphabetical(source)
            source.gsub(/[a-zA-Z]/, '')
          end

          def get_date_format(date)
            year = remove_alphabetical(date).to_i
            if year < 100
              Postpaid::Constant::MMMYY
            else
              Postpaid::Constant::MMMYYYY
            end
          end
        end
      end
    end
  end
end
