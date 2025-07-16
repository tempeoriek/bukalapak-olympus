class AddIndexAndResponseCodeColumnToCreditCardBillTransaction < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :credit_card_bill_transactions, throttler: throttler do |t|
      t.add_column :response_code, "tinyint unsigned"

      t.add_index [:processed_at, :state], 'index_credit_card_bill_transactions_on_reconcile_list'
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :credit_card_bill_transactions, throttler: throttler do |t|
      t.remove_column :response_code

      t.remove_index [:processed_at, :state], 'index_credit_card_bill_transactions_on_reconcile_list'
    end
  end
end
