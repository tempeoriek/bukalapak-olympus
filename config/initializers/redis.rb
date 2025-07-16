require 'redis'

if ENV['REDIS_USE_SENTINEL'].to_i == 1
  
  SENTINELS = [{ host: ENV['REDIS_SENTINEL_1'], port: 26379 },
               { host: ENV['REDIS_SENTINEL_2'], port: 26379 },
               { host: ENV['REDIS_SENTINEL_3'], port: 26379 }]

  RedisOlympus = Redis.new(url: "redis://mymaster", sentinels: SENTINELS, role: :master)
else
  RedisOlympus = Redis.new(
    host: ENV['REDIS_HOST'],
    port: ENV['REDIS_PORT'],
    db: ENV['REDIS_DB'],
  )
end
