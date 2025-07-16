# frozen_string_literal: true

module Toggle
  module CreditCardBill
    class WhitelistNewBNI < ::Toggle::Base
      def self.description
        '[REST-2947] Toggle to whitelist for new BNI partner'
      end
    end
  end
end
