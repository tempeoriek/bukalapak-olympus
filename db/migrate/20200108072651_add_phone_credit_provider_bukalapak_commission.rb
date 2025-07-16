class AddPhoneCreditProviderBukalapakCommission < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :phone_credit_providers, throttler: throttler do |t|
      t.add_column :bukalapak_commission, "int unsigned"
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :phone_credit_providers, throttler: throttler do |t|
      t.remove_column :bukalapak_commission
    end
  end
end
