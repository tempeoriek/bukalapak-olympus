class CreatePdamRecurrenceTemplateDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :pdam_recurrence_template_details do |t|
      t.string  :customer_number
      t.string  :customer_name
      t.integer :operator_id
      t.integer :buyer_id, :width => 8
      t.integer :recursive_id

      t.timestamps
    end

    add_index :pdam_recurrence_template_details, :recursive_id, :name => 'pdam_recurrence_template_on_recursive_id'
  end
end
