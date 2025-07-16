class ElectricityPostpaidRecurrenceTemplateDetail < ApplicationRecord
  def as_json(_options={})
    result = super(
      only: [
        :id,
        :customer_number,
        :customer_name,
        :segmentation,
        :power,
        :buyer_id,
        :recursive_id
      ]
    )
    result['image_url'] = image_url

    result
  end

  def image_url
    'https://s4.bukalapak.com/images/virtual_product/logo_pln.png'
  end
end
