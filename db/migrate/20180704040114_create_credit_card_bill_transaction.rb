class CreateCreditCardBillTransaction < ActiveRecord::Migration[5.1]
  def change
    create_table :credit_card_bill_transactions do |t|
      t.bigint    :buyer_id, :width => 8
      t.string    :customer_name
      t.string    :customer_number
      t.date      :statement_date, null: true
      t.date      :due_date, null: true
      t.integer   :amount
      t.integer   :minimum_payment, null: true
      t.integer   :bukalapak_admin_charge
      t.integer   :partner_admin_charge
      t.integer   :state
      t.integer   :transaction_type
      t.integer   :credit_card_biller_id
      t.integer   :credit_card_bill_partner_id
      t.string    :reference_number
      t.string    :token
      t.string    :card_data
      t.string    :partner_financial_journal_number
      t.string    :partner_journal_number
      t.string    :partner_transaction_id, null: true
      t.bigint    :remote_transaction_id, null: true, :width => 8
      t.bigint    :invoice_id, null: true, :width => 8
      t.datetime  :paid_at, null: true
      t.datetime  :processed_at, null: true
      t.datetime  :succeeded_at, null: true
      t.datetime  :failed_at, null: true

      t.timestamps
    end

    add_index :credit_card_bill_transactions, :buyer_id
    add_index :credit_card_bill_transactions, :state
    add_index :credit_card_bill_transactions, :credit_card_bill_partner_id, :name => 'index_credit_card_bill_transaction_on_partner_id'
    add_index :credit_card_bill_transactions, :remote_transaction_id
    add_index :credit_card_bill_transactions, :created_at
    add_index :credit_card_bill_transactions, :updated_at
    add_index :credit_card_bill_transactions, :credit_card_biller_id
  end
end
