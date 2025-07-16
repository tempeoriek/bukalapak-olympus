# frozen_string_literal: true

module Channel
  module Visa
    module CyberSource
      class SearchTransaction < Channel::Visa::CyberSource::Base

        PATH = 'tss/v2/searches'
        HTTP_METHOD = :post

        def initialize(client_reference_information_code:)
          @client_reference_information_code = client_reference_information_code
        end

        # Channel::Visa::CyberSource::SearchTransaction.new('20200620005708979735').send_request

        def send_request
          # Please check the API Reference here:
          # https://developer.cybersource.com/api-reference-assets/index.html#transaction-search_searchtransactions_create-a-search-request
          # https://developer.cybersource.com/api/developer-guides/dita-txn-search-details-rest-api-dev-guide-102718/txn_search_api/creating_txn_search_request.html

          response = super(custom_http_headers: {
            'Accept' => 'application/json;charset=utf-8'
          })
          JSON.parse(response).deep_symbolize_keys!
        end

        def payload
          @payload ||= {
            # save: "false",
            # name: "Search by Code",
            timezone: "Asia/Jakarta",
            # query: "clientReferenceInformation.code:#{@client_reference_information_code} AND submitTimeUtc:[NOW/DAY-7DAYS TO NOW/DAY+1DAY}",
            query: "clientReferenceInformation.code:#{@client_reference_information_code}",
            # offset: "0",
            # limit: "20",
            sort: "submitTimeUtc:desc",
          }
        end

      end
    end
  end
end
