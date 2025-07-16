class CreateMultifinanceTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :multifinance_transactions do |t|
      t.integer   :buyer_id, :width => 8
      t.string    :customer_name
      t.string    :customer_number
      t.string    :item_name, null: true
      t.string    :license_number, null: true
      t.string    :reference_number
      t.date      :due_date, null: true
      t.string    :installment_period, null: true
      t.integer   :partner
      t.integer   :amount
      t.integer   :penalty_fee
      t.integer   :bukalapak_admin_charge
      t.integer   :partner_admin_charge
      t.integer   :state
      t.integer   :multifinance_biller_id
      t.string    :partner_transaction_id, null: true
      t.integer   :remote_transaction_id, null: true, :width => 8
      t.integer   :invoice_id, null: true, :width => 8
      t.datetime  :paid_at, null: true
      t.datetime  :processed_at, null: true
      t.datetime  :succeeded_at, null: true
      t.datetime  :failed_at, null: true

      t.timestamps
    end

    add_index :multifinance_transactions, :buyer_id
    add_index :multifinance_transactions, :state
    add_index :multifinance_transactions, :partner
    add_index :multifinance_transactions, :remote_transaction_id
    add_index :multifinance_transactions, :created_at
    add_index :multifinance_transactions, :updated_at
    add_index :multifinance_transactions, :multifinance_biller_id
  end
end
