class AlterIntegerBigintPartnerBalance < ActiveRecord::Migration[5.1]
  def up
    change_column :electricity_postpaid_partners_balances, :amount, :bigint
    change_column :electricity_postpaid_partners_balances, :threshold, :bigint
  end

  def down
    change_column :electricity_postpaid_partners_balances, :amount, :integer
    change_column :electricity_postpaid_partners_balances, :threshold, :integer
  end
end
