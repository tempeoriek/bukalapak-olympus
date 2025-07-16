class AddReferenceNumberAndPartnerIdIndexCc < ActiveRecord::Migration[5.1]
  def self.up
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :credit_card_bill_transactions, throttler: throttler do |t|
      t.add_index [:reference_number]
      t.add_index [:partner_transaction_id]
    end
  end

  def self.down
    throttler = Lhm::Throttler::Time.new(stride: 1000)
    Lhm.change_table :credit_card_bill_transactions, throttler: throttler do |t|
      t.remove_index [:reference_number]
      t.remove_index [:partner_transaction_id]
    end
  end
end
