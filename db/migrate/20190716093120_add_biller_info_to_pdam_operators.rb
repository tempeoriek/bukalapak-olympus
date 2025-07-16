class AddBillerInfoToPdamOperators < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 1)
    Lhm.change_table :pdam_operators, throttler: throttler do |t|
      t.add_column :terms_and_conditions, "TEXT default null"
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 1)
    Lhm.change_table :pdam_operators, throttler: throttler do |t|
      t.remove_column :terms_and_conditions
    end
  end
end
