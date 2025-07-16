class AddTemplateIdAtPhoneCreditPostpaidTransaction < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 1)
    Lhm.change_table :phone_credit_postpaid_transactions, throttler: throttler do |t|
      t.add_column :template_detail_id, "bigint unsigned"
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 1)
    Lhm.change_table :phone_credit_postpaid_transactions, throttler: throttler do |t|
      t.remove_column :template_detail_id
    end
  end
end
