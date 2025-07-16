# frozen_string_literal: true

module Toggle
  module CreditCardBill
    class NewBNI < ::Toggle::Base
      def self.description
        '[REST-2945] Toggle to switch BNI partners to the new system'
      end
    end
  end
end
