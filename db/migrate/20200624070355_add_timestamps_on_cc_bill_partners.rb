class AddTimestampsOnCcBillPartners < ActiveRecord::Migration[5.1]
  def change
    add_column :credit_card_bill_partners, :created_at, :datetime, default: -> { 'NOW()' }
    add_column :credit_card_bill_partners, :updated_at, :datetime,default: -> { 'NOW()' }
  end
end
