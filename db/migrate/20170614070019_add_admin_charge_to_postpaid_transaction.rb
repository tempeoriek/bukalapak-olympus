class AddAdminChargeToPostpaidTransaction < ActiveRecord::Migration[5.1]
  def change
    add_column :postpaid_transactions, :admin_charge, :integer
  end
end
