class AddActiveToPdamOperators < ActiveRecord::Migration[5.1]
  def change
    add_column :pdam_operators, :active, :boolean
    add_index :pdam_operators, :active
  end
end
