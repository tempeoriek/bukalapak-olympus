# frozen_string_literal: true

module Channel
  module Visa
    module CyberSource
      class Payouts < Channel::Visa::CyberSource::Base

        PATH = 'pts/v2/payouts'
        HTTP_METHOD = :post

        def initialize(token:, amount:)
          @token = token
          @amount = amount
        end

        # Channel::Visa::CyberSource::Payouts.new('7010000000112271111', '100000').send_request

        def send_request
          # Please check the API Reference here:
          # https://developer.cybersource.com/api-reference-assets/index.html#payouts_payouts_process-a-payout
          #
          # Not helpful? Check this overrated documentation:
          # https://developer.cybersource.com/library/documentation/dev_guides/payouts_SO/Payouts_SO_API.pdf
          #
          # Can't find what you are looking for? Try this Github instead:
          # https://github.com/CyberSource/cybersource-rest-client-ruby
          # Its README.md files explain everything.

          response = super
          JSON.parse(response).deep_symbolize_keys!
        end

        def payload
          # The commented lines below are optional fields.
          @payload ||= {
            'clientReferenceInformation' => {
              'code' => generate_reference_code
            },
            'orderInformation' => {
              'amountDetails' => {
                'totalAmount' => @amount.to_s,
                'currency' => 'IDR'
              }
            },
            'merchantInformation' => {
              # 'categoryCode' => Channel::Config::VISA_CYBS_MERCHANT_CATEGORY_CODE,
              'merchantDescriptor' => {
                'name' => 'Bukalapak',
                # 'locality' => 'FC',
                # 'country' => 'US',
                # 'administrativeArea' => 'CA',
                # 'postalCode' => '94440'
              }
            },
            # 'recipientInformation' => {
            #   'firstName' => 'John',
            #   'lastName' => 'Doe',
            #   'address1' => 'Paseo Padre Boulevard',
            #   'locality' => 'Foster City',
            #   'administrativeArea' => 'CA',
            #   'country' => 'US',
            #   'postalCode' => '94400',
            #   'phoneNumber' => '6504320556',
            #   'dateOfBirth' => '19801009'
            # },
            # 'senderInformation' => {
            #   'referenceNumber' => '1234567890',
            #   'account' => {
            #     'fundsSource' => '01',
            #     'number' => '1234567890123456789012345678901234'
            #   },
            #   'name' => 'Thomas Jefferson',
            #   'address1' => '900 Metro Center Blvd.900',
            #   'locality' => 'Foster City',
            #   'administrativeArea' => 'CA',
            #   'countryCode' => 'US'
            # },
            # 'processingInformation' => {
            #   'businessApplicationId' => 'FD',
            #   'networkRoutingOrder' => 'ECG',
            #   'commerceIndicator' => 'internet'
            # },
            'paymentInformation' => {
              'customer' => {
                'customerId' => @token
              }
            }
          }
        end

        def reference_code
          payload['clientReferenceInformation']['code']
        end

        private

        def generate_reference_code
          return @token if Channel::Config::VISA_WIREMOCK.present?
          date = Time.now.in_time_zone.strftime("%Y%m%d%H%M%S%5N")
          "#{date}#{Random.rand(10)}"
        end

      end
    end
  end
end
