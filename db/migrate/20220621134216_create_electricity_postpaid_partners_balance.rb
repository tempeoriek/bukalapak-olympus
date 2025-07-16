class CreateElectricityPostpaidPartnersBalance < ActiveRecord::Migration[5.2]
  def change
    create_table :electricity_postpaid_partners_balances do |t|
      t.integer :electricity_postpaid_partners_id, :width => 3
      t.integer :amount
      t.integer :threshold
      t.integer :type , :width => 2

      t.timestamps
    end

    add_index :electricity_postpaid_partners_balances, :electricity_postpaid_partners_id, :name => 'electricity_postpaid_partners_balances_on_partners_id'
  end
end
