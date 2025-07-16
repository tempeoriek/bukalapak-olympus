# frozen_string_literal: true

module Channel
  module Visa
    module CyberSource
      class DeleteToken < Channel::Visa::CyberSource::Base

        PATH = 'tms/v1/instrumentidentifiers'
        HTTP_METHOD = :delete
        PROFILE_ID = Channel::Config::VISA_CYBS_TOKEN_VAULT_PROFILE_ID
        TOKEN_DELETION_SUCCESS_HTTP_CODE = '204'

        def initialize(token: nil)
          @token = token
          @path = PATH
        end

        # Channel::Visa::CyberSource::DeleteToken.new(token: 7010000000112271111).send_request

        def send_request
          # Please check the API Reference here:
          # https://developer.cybersource.com/api-reference-assets/index.html#token-management_instrument-identifier

          @path = "#{PATH}/#{@token}"
          censored_url = url(exclude_token: true)
          response = super(censored_url: censored_url)
          response&.net_http_res&.code.to_s == TOKEN_DELETION_SUCCESS_HTTP_CODE
        end

        def url(exclude_token: false)
          token = exclude_token ? '' : "/#{@token}"
          "#{api_protocol}://#{Channel::Config::VISA_CYBS_API_HOST}/#{PATH}#{token}"
        end

        def path
          @path
        end

      end
    end
  end
end
