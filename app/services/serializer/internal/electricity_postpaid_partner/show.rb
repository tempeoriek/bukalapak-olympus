# frozen_string_literal: true

module Serializer
  module Internal
    module ElectricityPostpaidPartner
      class Show
        attr_reader :partner

        def initialize(partner)
          @partner = partner
        end

        def as_json(_options = {})
          {
            id: partner.id,
            name: partner.name,
            state: partner.state
          }
        end
      end
    end
  end
end
