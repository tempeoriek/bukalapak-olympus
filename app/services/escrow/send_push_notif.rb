# frozen_string_literal: true

module Escrow
  class SendPushNotif
    URL = "#{Channel::Config::TELOLET_URL}/_internal/publishers/push-notifications"
    AUTH = "Basic #{Channel::Config::TELOLET_AUTH_KEY}"

    def initialize(payload, target='normal')
      @payload     = payload.merge({
        source:  'olympus',
        queue:   'notification.push_notification',
        version: '1.0'
      })
      @platforms = case target
        when 'normal' then %w[android ios chromeweb firefox safari]
        when 'agent'  then %w[mitra_android mitra_pwa]
      end
    end

    def run!
      @platforms.each do |platform|
        @payload[:data][:platform] = platform
        Channel::Connection::Http.post(URL, AUTH, @payload)
      end
    end
  end
end
