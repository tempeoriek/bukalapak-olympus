class CreateElectricityPostpaidRecurrenceTemplateDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :electricity_postpaid_recurrence_template_details do |t|
      t.string  :customer_number
      t.string  :customer_name
      t.string  :segmentation
      t.integer :power
      t.integer :buyer_id, :width => 8
      t.integer :recursive_id

      t.timestamps
    end

    add_index :electricity_postpaid_recurrence_template_details, :recursive_id, :name => 'electricity_recurrence_template_on_recursive_id'
  end
end
