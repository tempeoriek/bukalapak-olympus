require 'neo_client'

NeoClient.configure do |n|
  n.neo_host = ENV['NEO_HOST']
end
