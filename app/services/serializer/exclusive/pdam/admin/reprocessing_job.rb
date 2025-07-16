# frozen_string_literal: true

module Serializer::Exclusive::Pdam::Admin
  class ReprocessingJob
    attr_reader :object

    def initialize(object)
      @object = object
    end

    def as_json(_options = {})
      {
        id: object.id,
        state: object.state,
        stuck_transaction_date: object.stuck_transaction_date,
        triggered_by_user_id: object.triggered_by_user_id,
        triggered_by_user_name: object.triggered_by_user_name,
        created_at: object.created_at,
        updated_at: object.updated_at
      }
    end
  end
end
