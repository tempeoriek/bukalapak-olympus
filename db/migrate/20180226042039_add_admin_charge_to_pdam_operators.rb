class AddAdminChargeToPdamOperators < ActiveRecord::Migration[5.1]
  def change
    add_column :pdam_operators, :bukalapak_admin_charge, :integer, :default => 0
    add_column :pdam_operators, :partner_admin_charge, :integer, :default => 0
  end
end
