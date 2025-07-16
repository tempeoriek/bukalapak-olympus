# frozen_string_literal: true

module Toggle
  class Base
    class << self
      DEFAULT_PLATFORM = 'other' # used for backend service only

      # `.active?` is used for state checking only! For more references on the params please
      # check https://gitlab.cloud.bukalapak.io/bukalapak/neo-client-rb#get-toggle
      # If you use segmentation, please override `.active?`
      # @param `platform` [String]
      # @param `user_id` [Integer], currently by default is nil but provide it anyway because Neo is providing whitelisting mechanism
      #
      # @return [Boolean] toggle state, will default to false when there is error
      def active?(platform = DEFAULT_PLATFORM, user_id = nil)
        toggle_instance(platform, user_id).active?
      rescue StandardError => e
        Rails.logger.error(
          message: "Toggle '#{toggle_name}' encountered #{e.class}: #{e.message}. It will use false as default toggle state",
          tags: ['toggle', 'neo', toggle_name]
        )

        false
      end

      # when this is called from subclass which inherit ::Toggle::Base, e.g ::Toggle::CircuitBreaker::ElectricityPostpaid::Tektaya
      # it will return `olympus/toggle/circuit_breaker/electricity_postpaid/tektaya` otherwise will return `olympus/toggle/base`
      def toggle_name
        "olympus/#{self.name.underscore}"
      end

      protected

      # @return [::NeoClient::Toggle]
      def toggle_instance(platform, user_id)
        NeoClient::Search.toggle(toggle_name, platform, user_id)
      end
    end
  end
end
