class AddCreatedOnPostpaidTransactions < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000,  delay: 0.3)
    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.add_column :created_on_platform, 'VARCHAR(20)'
      t.add_column :created_on_version, 'INT(3) UNSIGNED'
      t.add_index [:created_on_platform, :created_on_version], 'index_postpaid_transactions_on_platform_and_version'
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000,  delay: 0.3)
    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.remove_index [:created_on_platform, :created_on_version], 'index_postpaid_transactions_on_platform_and_version'
      t.remove_column :created_on_platform
      t.remove_column :created_on_version
    end
  end
end


