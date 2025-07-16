class CreatePdamBills < ActiveRecord::Migration[5.1]
  def change
    create_table :pdam_bills do |t|
      t.date    :bill_period
      t.integer :penalty_fee
      t.integer :amount
      t.string  :cubication
      t.integer :pdam_transaction_id

      t.timestamps
    end

    add_index :pdam_bills, :pdam_transaction_id

  end
end
