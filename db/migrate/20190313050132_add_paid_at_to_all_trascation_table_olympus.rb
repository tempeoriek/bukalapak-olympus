class AddPaidAtToAllTrascationTableOlympus < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :phone_credit_postpaid_transactions, throttler: throttler do |t|
      t.add_column :paid_at, :datetime

      t.add_index [:paid_at], 'index_phone_credit_postpaid_transaction_on_paid_at'
    end
    
    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.add_column :paid_at, :datetime

      t.add_index [:paid_at], 'index_pdam_transaction_on_paid_at'
    end

    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.add_column :paid_at, :datetime

      t.add_index [:paid_at], 'index_bpjs_kesehatan_transaction_on_paid_at'
    end

    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.add_column :paid_at, :datetime

      t.add_index [:paid_at], 'index_postpaid_transaction_on_paid_at'
    end

    Lhm.change_table :credit_card_bill_transactions, throttler: throttler do |t|
      t.add_index [:paid_at], 'index_credit_card_bill_transaction_on_paid_at'
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :phone_credit_postpaid_transactions, throttler: throttler do |t|
      t.remove_column :paid_at

      # t.remove_index [:paid_at], 'index_phone_credit_postpaid_transaction_on_paid_at'
    end
    
    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.remove_column :paid_at

      # t.remove_index [:paid_at], 'index_pdam_transaction_on_paid_at'
    end

    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.remove_column :paid_at

      # t.remove_index [:paid_at], 'index_bpjs_kesehatan_transaction_on_paid_at'
    end

    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.remove_column :paid_at

      # t.remove_index [:paid_at], 'index_postpaid_transaction_on_paid_at'
    end

    Lhm.change_table :credit_card_bill_transactions, throttler: throttler do |t|
      t.remove_index [:paid_at], 'index_credit_card_bill_transaction_on_paid_at'
    end
  end
end
