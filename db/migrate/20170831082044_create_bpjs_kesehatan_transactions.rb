class CreateBpjsKesehatanTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :bpjs_kesehatan_transactions do |t|
      t.integer   :buyer_id
      t.integer   :invoice_id, null: true
      t.integer   :remote_transaction_id, null: true
      t.string    :partner_transaction_id, null: true
      t.integer   :partner
      t.string    :customer_number
      t.string    :customer_name
      t.integer   :family_member_count
      t.string    :branch_name
      t.integer   :amount
      t.integer   :admin_charge
      t.string    :payment_period
      t.string    :paid_until
      t.integer   :state
      t.datetime  :processed_at, null: true
      t.datetime  :succeeded_at, null: true
      t.datetime  :failed_at, null: true

      t.timestamps
    end

    add_index :bpjs_kesehatan_transactions, :buyer_id
    add_index :bpjs_kesehatan_transactions, :state
    add_index :bpjs_kesehatan_transactions, :partner
    add_index :bpjs_kesehatan_transactions, :remote_transaction_id
    add_index :bpjs_kesehatan_transactions, :created_at
    add_index :bpjs_kesehatan_transactions, :updated_at
  end
end
