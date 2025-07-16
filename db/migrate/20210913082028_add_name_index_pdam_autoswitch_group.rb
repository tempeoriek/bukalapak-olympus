class AddNameIndexPdamAutoswitchGroup < ActiveRecord::Migration[5.1]
  def change
    add_index :pdam_autoswitch_groups, :name
  end
end
