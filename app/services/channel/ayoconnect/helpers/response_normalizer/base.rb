# frozen_string_literal: true

module Channel
  module Ayoconnect
    module Helpers
      module ResponseNormalizer
        module Base
          # There are some attributes that appear to be dynamic from Ayoconnect response.
          #
          # Ex:
          # customerDetails, billDetails, productDetails, extraFields
          #
          # This provides helper to go through all the details.
          # -> details = one of the details from the response, must be in array form.
          def extract_details(details)
            result = {}

            details.each do |obj|
              key   = obj['key']
              value = obj['value']

              result[key] = value
            end

            result
          end
        end
      end
    end
  end
end
