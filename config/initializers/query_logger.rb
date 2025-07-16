# frozen_string_literal: true

ActiveSupport::Notifications.subscribe('sql.active_record') do |_, start, finish, _, payload|
  QueryLogger::Sql.log(start, finish, payload)
end
