class AddStatusToPdamOperatorCommissionSetting < ActiveRecord::Migration[5.2]
  def self.up
    add_column :pdam_operator_commission_settings, :state, 'tinyint after pdam_operator_id'
  end

  def self.down
    remove_column :pdam_operator_commission_settings, :state
  end
end
