module Partner
  module ElectricityPostpaid
    class AyoconnectController < ApplicationController
      include Postpaid::Constant
      include Response
      include Authenticate

      def callbacks
        authenticated = http_basic_authenticate_partner(AYOCONNECT)
        # this is to avoiding double render
        return unless authenticated == true

        # This API doesn't do anything at the moment
        # It's not part of our flow but it's required by the partner

        render_response('ok', 200)
      end
    end
  end
end
