# frozen_string_literal: true

module Channel
  module Notif
    PUSH_URL = "#{Channel::Config::TELOLET_URL}/_internal/publishers/push-notifications"
    ONSITE_URL = "#{Channel::Config::TELOLET_URL}/_internal/publishers/onsite"
    EMAIL_URL = "#{Channel::Config::TELOLET_URL}/_internal/publishers/emails"
    AUTH = "Basic #{Channel::Config::TELOLET_AUTH_KEY}"

    module_function

    def send_email(user, payload, opts = {})
      payload = build_email_payload(user, payload, opts)
      Channel::Connection::Http.post(EMAIL_URL, AUTH, payload)
    end

    def send_onsite(payload, target='normal')
      payload = payload.merge({
        source:  'olympus',
        queue:   'notification.onsite',
        version: '1.0'
      })
      platforms = case target
        when 'normal' then %w[onsite_web onsite_app]
        when 'agent'  then %w[onsite_agenlite]
      end
      platforms.each do |platform|
        payload[:onsite_platform] = platform
        Channel::Connection::Http.post(ONSITE_URL, AUTH, payload)
      end
    end

    def send_push(payload, target='normal')
      payload = payload.merge({
        source:  'olympus',
        queue:   'notification.push_notification',
        version: '1.0'
      })
      platforms = case target
        when 'normal' then %w[android ios chromeweb firefox safari]
        when 'agent'  then %w[mitra_android mitra_pwa]
      end
      platforms.each do |platform|
        payload[:data][:platform] = platform
        Channel::Connection::Http.post(PUSH_URL, AUTH, payload)
      end
    end

    private

    module_function

    def build_email_payload(user, payload, opts = {})
      {
        data: {
          body: payload[:body],
          recipient_address: [user[:email]].flatten,
          reply_to: "Reply Bukalapak.com <chat@reply.bukalapak.com>",
          sender_address: "Bukalapak.com <mail@noreply.bukalapak.com>",
          subject: payload[:subject],
          tag: payload[:tag],
          user_id: user[:user_id]
        }.merge(opts),
        queue: "notification.email",
        source: "olympus",
        version: "1.0"
      }
    end
  end
end
