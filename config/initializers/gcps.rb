# frozen_string_literal: true

require 'google/cloud/pubsub'

GoogleCloudPubSub ||= unless Rails.env.test?
  pubsub_credentials_string = Base64.decode64(ENV['PUBSUB_CREDENTIALS_64'])
  pubsub_credentials_hash = JSON.parse(pubsub_credentials_string)
  Google::Cloud::PubSub.new(
    project_id: ENV['GCP_PROJECT_ID'],
    credentials: pubsub_credentials_hash
  )
end
