class CreateVehicleTaxTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :vehicle_tax_transactions do |t|
      t.integer   :buyer_id
      t.integer   :invoice_id, limit: 8
      t.integer   :remote_transaction_id, limit: 8
      t.string    :partner_transaction_id
      t.string    :bill_code
      t.string    :state
      t.integer   :amount
      t.integer   :admin_fee, default: 0
      t.integer   :partner_fee, default: 0
      t.text      :notes
      t.string    :ntb
      t.datetime  :processed_at
      t.datetime  :succeeded_at
      t.datetime  :failed_at

      t.timestamps
    end

    add_index :vehicle_tax_transactions, :invoice_id
    add_index :vehicle_tax_transactions, [:buyer_id, :invoice_id]
    add_index :vehicle_tax_transactions, :bill_code
    add_index :vehicle_tax_transactions, :remote_transaction_id
  end
end
