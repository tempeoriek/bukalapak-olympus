require 'json'
require 'rest-client'

class Notification
  def self.slack_notif
    url = 'https://hooks.slack.com/services/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'
    params = {text: "OLYMPUS Tag is changed to #{ENV['AT_RUN_TAGS']} by #{ENV['GITLAB_USER_NAME']}. \n cc: #{ENV['TE_POSTPAID']}"}.to_json

    if ENV['AT_RUN_TAGS'] != ENV['TE_DEFAULT_TAG']
      RestClient.post( url, params)
    end
  end
end
