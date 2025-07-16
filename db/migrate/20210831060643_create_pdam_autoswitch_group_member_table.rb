class CreatePdamAutoswitchGroupMemberTable < ActiveRecord::Migration[5.1]
  def change
    create_table :pdam_autoswitch_group_members do |t|
      t.integer  :autoswitch_group_id
      t.integer  :operator_id
      t.integer  :state, :limit => 1

      t.timestamps
    end

    add_index :pdam_autoswitch_group_members, :autoswitch_group_id
    add_index :pdam_autoswitch_group_members, :operator_id
    add_index :pdam_autoswitch_group_members, :state
  end
end
