require 'toggleable'

module Toggleable
  class Logger < Toggleable::LoggerAbstract
    attr_accessor :logger

    def initialize
      @logger = Logger2
    end

    def log(key:, value:, actor:)
      Logger2.info(
        tags: ['toggleable'],
        key: key,
        message: {
          actor: actor,
          value: value
        }
      )
    end

    def error(message:)
      Logger2.error(
        tags: ['toggleable'],
        message: message
      )
    end
  end
end

toggleable_logger = Toggleable::Logger.new
toggleable_storage = Toggleable::RedisStore.new(RedisOlympus)

Toggleable.configure do |t|
  t.namespace = 'features'
  t.enable_palanca = false
  t.expiration_time = 5.minutes
  t.storage = toggleable_storage
  t.logger = toggleable_logger
  t.use_memoization = Rails.env.production?
end
