class CreatePhoneCreditPostpaidRecurrenceTemplateDetail < ActiveRecord::Migration[5.1]
  def change
    create_table :phone_credit_postpaid_recurrence_template_details, id: :bigint, unsigned: true do |t|
      t.bigint  :customer_number
      t.string  :customer_name
      t.bigint  :buyer_id
      t.integer :recursive_id

      t.timestamps
    end

    add_index :phone_credit_postpaid_recurrence_template_details, :recursive_id, :name => 'phone_credit_postpaid_template_on_recursive_id'
  end
end
