# frozen_string_literal: true

module Toggle
  class AutoRefundConfirmTransactionNotFound < ::Toggle::Base
    def self.description
      '[O2OVPD-1464] Toggle to enable auto refund transaction when confirm transaction not found'
    end
  end
end
