class AddQuickpayIndexToEachTransactions < ActiveRecord::Migration[5.1]
  def up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.add_index [:buyer_id, :state, :succeeded_at], 'index_postpaid_transactions_on_quickpay_list'
    end
    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.add_index [:buyer_id, :state, :succeeded_at], 'index_bpjs_kesehatan_transactions_on_quickpay_list'
    end
    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.add_index [:buyer_id, :state, :succeeded_at], 'index_pdam_transactions_on_quickpay_list'
    end
    Lhm.change_table :multifinance_transactions, throttler: throttler do |t|
      t.add_index [:buyer_id, :state, :succeeded_at], 'index_multifinance_transactions_on_quickpay_list'
    end
    Lhm.change_table :phone_credit_postpaid_transactions, throttler: throttler do |t|
      t.add_index [:buyer_id, :state, :succeeded_at], 'index_phone_credit_postpaid_transactions_on_quickpay_list'
    end
  end

  def down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :postpaid_transactions, throttler: throttler do |t|
      t.remove_index [:buyer_id, :state, :succeeded_at], 'index_postpaid_transactions_on_quickpay_list'
    end
    Lhm.change_table :bpjs_kesehatan_transactions, throttler: throttler do |t|
      t.remove_index [:buyer_id, :state, :succeeded_at], 'index_bpjs_kesehatan_transactions_on_quickpay_list'
    end
    Lhm.change_table :pdam_transactions, throttler: throttler do |t|
      t.remove_index [:buyer_id, :state, :succeeded_at], 'index_pdam_transactions_on_quickpay_list'
    end
    Lhm.change_table :multifinance_transactions, throttler: throttler do |t|
      t.remove_index [:buyer_id, :state, :succeeded_at], 'index_multifinance_transactions_on_quickpay_list'
    end
    Lhm.change_table :phone_credit_postpaid_transactions, throttler: throttler do |t|
      t.remove_index [:buyer_id, :state, :succeeded_at], 'index_phone_credit_postpaid_transactions_on_quickpay_list'
    end
  end
end
