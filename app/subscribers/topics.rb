# frozen_string_literal: true

# This class is separated from base so it will be
# initialized and can be used after start up
module Subscribers
  module Topics
    PARTNER_PROCESS = 'olympus.partner_process'
    PARTNER_PROCESS_CREDIT_CARD_BILL = 'olympus.partner_process_ccb'
    PARTNER_CONFIRM = 'olympus.partner_confirm'
    EMAIL_NOTIF = 'olympus.email_notif'
    UPDATE_REMOTE = 'olympus.update_remote'
    SIEVEX_PREDICT = 'olympus.sievex_predict'

    module_function

    def get_delay(topic_name)
      hash_of_time = {
        PARTNER_PROCESS => (0.1 + rand(5)),
        PARTNER_PROCESS_CREDIT_CARD_BILL => (0.1 + rand(5)),
        PARTNER_CONFIRM => ENV.fetch('PARTNER_CONFIRM_DELAY', 30).to_i,
        EMAIL_NOTIF => 0.1,
        UPDATE_REMOTE => 0.1,
        SIEVEX_PREDICT => ENV.fetch('SIEVEX_PREDICT_DELAY').to_i
      }
      hash_of_time[topic_name]
    end
  end
end 
