# frozen_string_literal: true

module Channel
  module Tektaya
    module Helpers
      module Constants
        # Host configs
        TEKTAYA_HOST = Channel::Config::TEKTAYA_HOST

        # Host URL
        TEKTAYA_POSTPAID_URL = Channel::Config::TEKTAYA_POSTPAID_URL
        TEKTAYA_LOGIN_URL = Channel::Config::TEKTAYA_LOGIN_URL

        # BL configs
        BL_USER_ID  = Channel::Config::TEKTAYA_BL_USER_ID
        BL_PASSWORD = Channel::Config::TEKTAYA_BL_PASSWORD
        BL_BIT62    = Channel::Config::TEKTAYA_BL_BIT62

        # BMI configs
        BMI_USER_ID  = Channel::Config::TEKTAYA_BMI_USER_ID
        BMI_PASSWORD = Channel::Config::TEKTAYA_BMI_PASSWORD
        BMI_BIT62    = Channel::Config::TEKTAYA_BMI_BIT62

        # BMI BukaConnect configs
        BMI_BUKACONNECT_USER_ID  = Channel::Config::TEKTAYA_BMI_BUKACONNECT_USER_ID
        BMI_BUKACONNECT_PASSWORD = Channel::Config::TEKTAYA_BMI_BUKACONNECT_PASSWORD
        BMI_BUKACONNECT_BIT62    = Channel::Config::TEKTAYA_BMI_BUKACONNECT_BIT62

        # general
        LOGIN_MTI                   = '58'
        MITRA_BUYER_TYPE            = 'mitra'
        NORMAL_BUYER_TYPE           = 'normal'
        BUKACONNECT_BUYER_TYPE      = 'collecting_agent'
        BL_SESSION_KEY              = 'olympus::tektaya::bl::sessionkey'
        BMI_SESSION_KEY             = 'olympus::tektaya::bmi::sessionkey'
        BMI_BUKACONNECT_SESSION_KEY = 'olympus::tektaya::bmi_bukaconnect::sessionkey'

        # electricity postpaid
        ELECTRICITY_POSTPAID_INQUIRY_MTI = '38'
        ELECTRICITY_POSTPAID_PAYMENT_MTI = '17'

        #circuit box configuration
        CIRCUITBOX_SLEEP_WINDOW = 60
        CIRCUITBOX_TIME_WINDOW = 30
        CIRCUITBOX_VOLUME_THRESHOLD = 10
        CIRCUITBOX_ERROR_THRESHOLD = 50
      end
    end
  end
end
