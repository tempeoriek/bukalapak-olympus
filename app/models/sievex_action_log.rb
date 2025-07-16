class SievexActionLog < ApplicationRecord
  validates_presence_of :entity_id, :entity_type, :actor, :reason

  enum entity_type: {
    ::Sievex::Base::CREDIT_CARD_BILL_ENTITY => 0
  }
end
