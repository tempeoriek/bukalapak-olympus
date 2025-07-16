class EditRemoteTransactionIdBuyerIdToBigint < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 500)

    Lhm.change_table :bpjs_kesehatan_recurrence_template_details, throttler: throttler do |t|
      t.change_column :buyer_id, :bigint
    end

    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.change_column :buyer_id, :bigint
      t.change_column :remote_transaction_id, :bigint
    end

    Lhm.change_table :electricity_postpaid_recurrence_template_details, throttler: throttler do |t|
      t.change_column :buyer_id, :bigint
    end

    Lhm.change_table :pdam_recurrence_template_details, throttler: throttler do |t|
      t.change_column :buyer_id, :bigint
    end

    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.change_column :buyer_id, :bigint
      t.change_column :remote_transaction_id, :bigint
    end

    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.change_column :buyer_id, :bigint
      t.change_column :remote_transaction_id, :bigint
    end

    Lhm.change_table :vehicle_tax_bills, throttler: throttler do |t|
      t.change_column :buyer_id, :bigint
    end

    Lhm.change_table :vehicle_tax_transactions, throttler: throttler do |t|
      t.change_column :buyer_id, :bigint
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 500)

    Lhm.change_table :bpjs_kesehatan_recurrence_template_details, throttler: throttler do |t|
      t.change_column :buyer_id, :integer
    end

    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.change_column :buyer_id, :integer
      t.change_column :remote_transaction_id, :integer
    end

    Lhm.change_table :electricity_postpaid_recurrence_template_details, throttler: throttler do |t|
      t.change_column :buyer_id, :integer
    end

    Lhm.change_table :pdam_recurrence_template_details, throttler: throttler do |t|
      t.change_column :buyer_id, :integer
    end

    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.change_column :buyer_id, :integer
      t.change_column :remote_transaction_id, :integer
    end

    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.change_column :buyer_id, :integer
      t.change_column :remote_transaction_id, :integer
    end

    Lhm.change_table :vehicle_tax_bills, throttler: throttler do |t|
      t.change_column :buyer_id, :integer
    end

    Lhm.change_table :vehicle_tax_transactions, throttler: throttler do |t|
      t.change_column :buyer_id, :integer
    end
  end
end
