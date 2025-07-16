class AddNewStates < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 1)
    Lhm.change_table :credit_card_bill_transactions, throttler: throttler do |t|
      t.add_column :partner_succeeded_at, :datetime
      t.add_column :partner_failed_at, :datetime
    end

    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.add_column :partner_succeeded_at, :datetime
      t.add_column :partner_failed_at, :datetime
      t.add_column :cancelled_at, :datetime
      t.add_column :expired_at, :datetime
    end

    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.add_column :partner_succeeded_at, :datetime
      t.add_column :partner_failed_at, :datetime
      t.add_column :cancelled_at, :datetime
      t.add_column :expired_at, :datetime
    end

    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.add_column :partner_succeeded_at, :datetime
      t.add_column :partner_failed_at, :datetime
      t.add_column :cancelled_at, :datetime
      t.add_column :expired_at, :datetime
    end

    Lhm.change_table :phone_credit_postpaid_transactions, throttler: throttler do |t|
      t.add_column :partner_succeeded_at, :datetime
      t.add_column :partner_failed_at, :datetime
      t.add_column :cancelled_at, :datetime
      t.add_column :expired_at, :datetime
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000, delay: 1)
    Lhm.change_table :credit_card_bill_transactions, throttler: throttler do |t|
      t.remove_column :cancelled_at
      t.remove_column :expired_at
    end

    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.remove_column :partner_succeeded_at
      t.remove_column :partner_failed_at
      t.remove_column :cancelled_at
      t.remove_column :expired_at
    end

    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.remove_column :partner_succeeded_at
      t.remove_column :partner_failed_at
      t.remove_column :cancelled_at
      t.remove_column :expired_at
    end

    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.remove_column :partner_succeeded_at
      t.remove_column :partner_failed_at
      t.remove_column :cancelled_at
      t.remove_column :expired_at
    end

    Lhm.change_table :phone_credit_postpaid_transactions, throttler: throttler do |t|
      t.remove_column :partner_succeeded_at
      t.remove_column :partner_failed_at
      t.remove_column :cancelled_at
      t.remove_column :expired_at
    end
  end
end
