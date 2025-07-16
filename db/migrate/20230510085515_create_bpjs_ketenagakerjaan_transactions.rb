class CreateBpjsKetenagakerjaanTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :bpjs_ketenagakerjaan_transactions do |t|
      t.bigint    :buyer_id
      t.bigint    :invoice_id
      t.bigint    :remote_transaction_id
      t.string    :partner_transaction_id
      t.integer   :partner
      t.string    :customer_number
      t.string    :customer_name
      t.string    :branch_name
      t.integer   :admin_charge
      t.string    :payment_period
      t.date      :start_bill_period
      t.date      :end_bill_period
      t.string    :paid_until
      t.integer   :state
      t.integer   :amount, default: 0, unsigned: true
      t.datetime  :processed_at
      t.datetime  :succeeded_at
      t.datetime  :failed_at
      t.datetime  :created_at, null: false
      t.datetime  :updated_at, null: false
      t.datetime  :paid_at
      t.datetime  :partner_succeeded_at
      t.datetime  :partner_failed_at
      t.datetime  :cancelled_at
      t.datetime  :expired_at
      t.string    :reference_number
      t.string    :info
      t.string    :phone_number, default: ""
      t.bigint    :template_detail_id
      t.integer   :transaction_type
      t.integer   :bukalapak_admin_charge
      t.integer   :partner_admin_charge
      t.integer   :revenue, limit: 3, default: 0, unsigned: true
      t.datetime  :revenue_at
      t.integer   :bpjs_tk_type
      t.string    :division
      t.string    :npp
      t.string    :bill_code

      t.timestamps
    end

    add_index :bpjs_ketenagakerjaan_transactions, [:buyer_id, :state, :succeeded_at], :name => 'index_bpjstk_transactions_on_buyer_id_and_state_and_succeeded_at'
    add_index :bpjs_ketenagakerjaan_transactions, :buyer_id
    add_index :bpjs_ketenagakerjaan_transactions, :created_at
    add_index :bpjs_ketenagakerjaan_transactions, :paid_at
    add_index :bpjs_ketenagakerjaan_transactions, :partner
    add_index :bpjs_ketenagakerjaan_transactions, :succeeded_at
    add_index :bpjs_ketenagakerjaan_transactions, :remote_transaction_id
    add_index :bpjs_ketenagakerjaan_transactions, :revenue_at
    add_index :bpjs_ketenagakerjaan_transactions, :state
    add_index :bpjs_ketenagakerjaan_transactions, :updated_at
  end
end


