class CreateBills < ActiveRecord::Migration[5.1]
  def change
    create_table :bills do |t|
      t.date    :bill_period
      t.date    :due_date
      t.integer :penalty_fee
      t.integer :amount
      t.string  :previous_meter
      t.string  :current_meter
      t.integer :postpaid_transaction_id

      t.timestamps
    end

    add_index :bills, :postpaid_transaction_id
  end
end
