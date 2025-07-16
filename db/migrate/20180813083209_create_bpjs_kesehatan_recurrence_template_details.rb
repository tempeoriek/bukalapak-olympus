class CreateBpjsKesehatanRecurrenceTemplateDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :bpjs_kesehatan_recurrence_template_details do |t|
      t.string  :customer_number
      t.string  :customer_name
      t.string  :phone_number
      t.integer :family_member_count
      t.integer :buyer_id, :width => 8
      t.integer :recursive_id

      t.timestamps
    end

    add_index :bpjs_kesehatan_recurrence_template_details, :recursive_id, :name => 'bpjs_recurrence_template_on_recursive_id'
  end
end
