# frozen_string_literal: true

module Channel
  module Bukopin
    class ElectricityPostpaid
      module Constants

        module Mti
          NETWORK = '2800'
          INQUIRY = '2100'
          PAYMENT = '2200'
          REVERSAL = '2400'
          REVERSAL_REPEAT = '2401'
          REVERSAL_RESPONSE = '2410'
          REVERSAL_REPEAT_RESPONSE = '2411'
        end

        module NetworkCodes
          SIGN_ON = '001'
          SIGN_OFF = '002'
          ECHO_TEST = '301'
          GET_KEY = '101'

          DESCRIPTION = {
            SIGN_ON => 'sign_on',
            SIGN_OFF => 'sign_off',
            ECHO_TEST => 'echo_test',
            GET_KEY => 'get_key'
          }
        end

        module ResponseCodes
          NEED_SIGN_ON = '0011'
          INVALID_SECURITY_DATA = '0096'
          SUCCESSFUL = '0000'
          REVERSAL_EXCEED_TIME_LIMIT = '0012'
          TIMEOUT_TO_PLN = '0068'
        end

        DEFAULT_TIMEOUT = (ENV['BUKOPIN_REQUEST_TIMEOUT'] || 40).to_i
        DEFAULT_INQUIRY_TIMEOUT = (ENV['BUKOPIN_INQUIRY_REQUEST_TIMEOUT'] || DEFAULT_TIMEOUT).to_i
        BUKOPIN_ENCRYPT_KEY = 'bukopin_encript_key'
        BUKOPIN_UNIQUE_NUMBER_KEY = 'bukopin:unique_number'
        BUKOPIN_ENCRYPT_KEY_BMI = 'bukopin_encript_key_bmi'
        BUKOPIN_UNIQUE_NUMBER_KEY_BMI = 'bukopin_bmi:unique_number'

        AGENT_USER = {
          host: Channel::Config::BUKOPIN_HOST_BMI,
          port: Channel::Config::BUKOPIN_PORT_BMI,
          private_key: Channel::Config::BUKOPIN_PRIVATE_KEY_BMI,
          partner_central_id: Channel::Config::BUKOPIN_PARTNER_CENTRAL_ID_BMI,
          encrypt_key: BUKOPIN_ENCRYPT_KEY_BMI,
          unique_number_key: BUKOPIN_UNIQUE_NUMBER_KEY_BMI,
          user_id: Channel::Config::BUKOPIN_USER_ID
        }

        NORMAL_USER = {
          host: Channel::Config::BUKOPIN_HOST,
          port: Channel::Config::BUKOPIN_PORT,
          private_key: Channel::Config::BUKOPIN_PRIVATE_KEY,
          partner_central_id: Channel::Config::BUKOPIN_PARTNER_CENTRAL_ID,
          encrypt_key: BUKOPIN_ENCRYPT_KEY,
          unique_number_key: BUKOPIN_UNIQUE_NUMBER_KEY,
          user_id: Channel::Config::BUKOPIN_USER_ID
        }

        AREA_CODE = '00'
        TRANSACTION_CODE = '000'
        ISO_CURRENCY_CODE = '360'
        CURRENCY_MINOR_UNIT = '0'

        PRIMARY_ACCOUNT_NUMBER = '99501'
        MERCHANT_CODE = '6021'
        BANK_CODE = '4410010'
        SWITCHER_ID = '0000000'

        # Private Information Detail
        module Parsers
          INQUIRY_48 = {
            switcher_id: 7,
            customer_number: 12,
            bill_status: 1,
            outstanding_bill: 2,
            reference_number: 32,
            customer_name: 25,
            service_unit: 5,
            service_unit_phone: 15,
            subscriber_segmentation: 4,
            power_consuming_category: 9,
            total_admin_charges: 9
          }.freeze

          PAYMENT_48 = {
            switcher_id: 7,
            customer_number: 12,
            bill_status: 1,
            payment_status: 1,
            outstanding_bill: 2,
            reference_number: 32,
            customer_name: 25,
            service_unit: 5,
            service_unit_phone: 15,
            subscriber_segmentation: 4,
            power_consuming_category: 9,
            total_admin_charges: 9
          }.freeze

          BILL_DETAILS = {
            bill_period: 6,
            due_date: 8,
            meter_read_date: 8,
            total_electricity_bill: 12,
            incentive: 11,
            value_added_tax: 10,
            penalty_fee: 12,
            previous_meter_reading: 8,
            current_meter_reading: 8,
            previous_meter_reading_2: 8,
            current_meter_reading_2: 8,
            previous_meter_reading_3: 8,
            current_meter_reading_3: 8
          }.freeze
        end
      end
    end
  end
end
