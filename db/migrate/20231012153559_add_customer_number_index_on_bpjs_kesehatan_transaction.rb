class AddCustomerNumberIndexOnBpjsKesehatanTransaction < ActiveRecord::Migration[5.2]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.add_index [:customer_number, :created_at], "index_cust_no_bpjs_kes_transaction"
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.remove_index [:customer_number, :created_at]
    end
  end
end
