class CreatePdamAutoswitchGroupMemberSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :pdam_autoswitch_group_member_settings do |t|
      t.integer :autoswitch_group_member_id
      t.integer :threshold_value
      t.integer :threshold_min_trx
      t.integer :threshold_period_in_seconds
      t.integer :threshold_type
      t.integer :threshold_state, :limit => 1

      t.timestamps
    end
  end
end
