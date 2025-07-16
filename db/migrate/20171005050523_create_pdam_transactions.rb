class CreatePdamTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :pdam_transactions do |t|
      t.integer   :buyer_id
      t.string    :customer_name
      t.string    :customer_number
      t.date      :start_bill_period
      t.date      :end_bill_period
      t.integer   :amount
      t.integer   :penalty_fee
      t.integer   :bukalapak_admin_charge
      t.integer   :partner_admin_charge
      t.integer   :state
      t.integer   :partner
      t.integer   :pdam_operator_id
      t.string    :partner_transaction_id, null: true
      t.integer   :remote_transaction_id, null: true
      t.integer   :invoice_id, null: true
      t.datetime  :processed_at, null: true
      t.datetime  :succeeded_at, null: true
      t.datetime  :failed_at, null: true

      t.timestamps
    end

    add_index :pdam_transactions, :buyer_id
    add_index :pdam_transactions, :state
    add_index :pdam_transactions, :partner
    add_index :pdam_transactions, :remote_transaction_id
    add_index :pdam_transactions, :created_at
    add_index :pdam_transactions, :updated_at
    add_index :pdam_transactions, :pdam_operator_id
  end
end
