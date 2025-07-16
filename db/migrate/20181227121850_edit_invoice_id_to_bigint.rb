require 'lhm'

class EditInvoiceIdToBigint < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 500)

    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.change_column :invoice_id, :bigint
    end

    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.change_column :invoice_id, :bigint
    end

    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.change_column :invoice_id, :bigint
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 500)

    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.change_column :invoice_id, :integer
    end

    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.change_column :invoice_id, :integer
    end

    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.change_column :invoice_id, :integer
    end
  end
end
