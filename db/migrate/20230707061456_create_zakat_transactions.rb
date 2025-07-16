class CreateZakatTransactions < ActiveRecord::Migration[5.2]
  def self.up
    create_table :zakat_transactions do |t|
      t.bigint   :buyer_id, nullable: false, unsigned: true
      t.string   :buyer_name, nullable: false
      t.bigint   :invoice_id, nullable: false, unsigned: true
      t.bigint   :remote_id, nullable: false, unsigned: true
      t.integer  :amount, nullable: false
      t.integer  :foundation_id, nullable: false
      t.integer  :partner, nullable: false
      t.integer  :state, nullable: false
      t.string   :created_on
      t.string   :notes
      t.datetime :expire_time
      t.datetime :succeeded_at
      t.datetime :failed_at
      t.datetime :revived_at
      t.integer  :kind, limit: 1, default: 0, nullable: false, unsigned: true
      t.integer  :revenue, limit: 3, default: 0, unsigned: true
      t.datetime :revenue_at
      t.datetime :paid_at
      t.datetime :invoiced_at

      t.timestamps

      t.index :remote_id
      t.index :state
      t.index :buyer_id
      t.index :created_at
      t.index :updated_at
      t.index :invoice_id
    end
  end

  def self.down
    drop_table :zakat_transactions
  end
end
