class BpjsKesehatanRecurrenceTemplateDetail < ApplicationRecord
  def as_json(_options={})
    result = super(
      only: [
        :id,
        :customer_number,
        :customer_name,
        :buyer_id,
        :recursive_id,
        :family_member_count
      ]
    )
    result['image_url'] = image_url

    result
  end

  def image_url
    'https://s4.bukalapak.com/images/virtual_product/logo_bpjs.png'
  end
end
