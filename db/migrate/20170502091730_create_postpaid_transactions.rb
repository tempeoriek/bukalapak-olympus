class CreatePostpaidTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :postpaid_transactions do |t|
      t.integer   :buyer_id
      t.string    :customer_name
      t.string    :customer_number
      t.integer   :power
      t.string    :segmentation
      t.string    :stand_meter
      t.integer   :outstanding_bill
      t.integer   :amount
      t.integer   :penalty_fee
      t.integer   :state
      t.integer   :partner
      t.string    :partner_transaction_id, null: true
      t.integer   :remote_transaction_id, null: true
      t.integer   :invoice_id, null: true
      t.datetime  :processed_at, null: true
      t.datetime  :succeeded_at, null: true
      t.datetime  :failed_at, null: true

      t.timestamps
    end

    add_index :postpaid_transactions, :buyer_id
    add_index :postpaid_transactions, :state
    add_index :postpaid_transactions, :partner
    add_index :postpaid_transactions, :remote_transaction_id
    add_index :postpaid_transactions, :created_at
    add_index :postpaid_transactions, :updated_at
  end
end
