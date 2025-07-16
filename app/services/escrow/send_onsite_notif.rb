# frozen_string_literal: true

module Escrow
  class SendOnsiteNotif
    URL = "#{Channel::Config::TELOLET_URL}/_internal/publishers/onsite"
    AUTH = "Basic #{Channel::Config::TELOLET_AUTH_KEY}"

    def initialize(payload, target='normal')
      @payload     = payload.merge({
        source:  'olympus',
        queue:   'notification.onsite',
        version: '1.0'
      })
      @platforms = case target
        when 'normal' then %w[onsite_web onsite_app]
        when 'agent'  then %w[onsite_agenlite]
      end
    end

    def run!
      @platforms.each do |platform|
        @payload[:onsite_platform] = platform
        Channel::Connection::Http.post(URL, AUTH, @payload)
      end
    end
  end
end
