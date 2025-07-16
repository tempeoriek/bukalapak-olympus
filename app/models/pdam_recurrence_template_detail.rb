class PdamRecurrenceTemplateDetail < ApplicationRecord
  has_one :operator, class_name: 'PdamOperator', foreign_key: 'id', primary_key: 'operator_id'

  def as_json(_options={})

    result = super(
      only: [
        :id,
        :customer_number,
        :customer_name,
        :operator_id,
        :buyer_id,
        :recursive_id,
      ],
      include: {
        operator: {
          only: [
            :id,
            :name,
            :group,
            :image_url
          ]
        }
      }
      )
  end
end