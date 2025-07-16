class CreatePhoneCreditPostpaidTransactions < ActiveRecord::Migration[5.1]
  def change
    create_table :phone_credit_postpaid_transactions do |t|
      t.bigint :buyer_id
      t.string :customer_name
      t.string :phone_number
      t.integer :reference_no
      t.integer :outstanding_bill
      t.date :start_bill_period
      t.date :end_bill_period
      t.integer :bill_amount
      t.integer :partner_admin_charge
      t.integer :bukalapak_admin_charge
      t.integer :total_amount
      t.integer :state
      t.bigint :provider_id
      t.string :partner_transaction_id
      t.bigint :remote_transaction_id
      t.bigint :invoice_id
      t.datetime  :processed_at, null: true
      t.datetime  :succeeded_at, null: true
      t.datetime  :failed_at, null: true
      t.timestamps
    end

    add_index :phone_credit_postpaid_transactions, :buyer_id
    add_index :phone_credit_postpaid_transactions, :state
    add_index :phone_credit_postpaid_transactions, :provider_id
    add_index :phone_credit_postpaid_transactions, :remote_transaction_id, :name => 'index_phone_credit_postpaid_on_remote_transcation_id'
    add_index :phone_credit_postpaid_transactions, :created_at
    add_index :phone_credit_postpaid_transactions, :updated_at
  end
end
