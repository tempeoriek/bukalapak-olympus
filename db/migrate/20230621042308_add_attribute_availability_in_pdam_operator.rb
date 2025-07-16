class AddAttributeAvailabilityInPdamOperator < ActiveRecord::Migration[5.2]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :pdam_operators, throttler: throttler do |t|
      t.add_column :have_issue, "integer default 0"
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :pdam_operators, throttler: throttler do |t|
      t.remove_column :have_issue
    end
  end
end
