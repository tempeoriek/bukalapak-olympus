class CreatePdamAutoswitchGroupTable < ActiveRecord::Migration[5.1]
  def change
    create_table :pdam_autoswitch_groups do |t|
      t.string   :name
      t.integer  :state, :limit => 1

      t.timestamps
    end

    add_index :pdam_autoswitch_groups, :state
  end
end
