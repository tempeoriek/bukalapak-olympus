module Partner
  module CreditCardBills
    class ThorController < ApplicationController
      include Postpaid::Constant
      include Response
      include Authenticate

      def callbacks
        authenticated = http_basic_authenticate_partner(THOR)
        return unless authenticated == true

        transaction = Action::CreditCardBillTransaction::Callbacks::Thor.new(params).run!

        render_response(transaction.as_json, 200)
      rescue ::Exceptions::InvalidStatusError => e # CHECK: this exception probably will never happen
        render_response({ 'message': 'OK' }, 200)
      end
    end
  end
end
