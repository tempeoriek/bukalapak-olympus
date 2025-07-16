# frozen_string_literal: true

module Channel
  module Tektaya
    module Helpers
      module BuyerType
        include Constants

        MITRA_BUYER_TYPE_CONFIG = {
          buyer_type: MITRA_BUYER_TYPE,
          user_id: BMI_USER_ID,
          password: BMI_PASSWORD,
          bit62: BMI_BIT62
        }.freeze

        NORMAL_BUYER_TYPE_CONFIG = {
          buyer_type: NORMAL_BUYER_TYPE,
          user_id: BL_USER_ID,
          password: BL_PASSWORD,
          bit62: BL_BIT62
        }.freeze

        BUKACONNECT_BUYER_TYPE_CONFIG = {
          buyer_type: BUKACONNECT_BUYER_TYPE,
          user_id: BMI_BUKACONNECT_USER_ID,
          password: BMI_BUKACONNECT_PASSWORD,
          bit62: BMI_BUKACONNECT_BIT62
        }.freeze

        def retrieve_buyer_type_config(buyer_type)
          case buyer_type
          when MITRA_BUYER_TYPE
            MITRA_BUYER_TYPE_CONFIG
          when NORMAL_BUYER_TYPE
            NORMAL_BUYER_TYPE_CONFIG
          when BUKACONNECT_BUYER_TYPE
            BUKACONNECT_BUYER_TYPE_CONFIG
          end
        end

        def determine_redis_key(buyer_type)
          case buyer_type
          when MITRA_BUYER_TYPE
            BMI_SESSION_KEY
          when NORMAL_BUYER_TYPE
            BL_SESSION_KEY
          when BUKACONNECT_BUYER_TYPE
            BMI_BUKACONNECT_SESSION_KEY
          else
            raise ::Exceptions::PartnerIssue.new('Cannot determine Tektaya session key')
          end
        end
      end
    end
  end
end
