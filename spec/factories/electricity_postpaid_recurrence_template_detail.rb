FactoryBot.define do
  factory :electricity_postpaid_recurrence_template_detail, class: ElectricityPostpaidRecurrenceTemplateDetail do
    id 1
    customer_number '12345'
    customer_name 'BADRUN'
    power 900
    segmentation 'R1'
    buyer_id 1
    recursive_id 1
  end
end
