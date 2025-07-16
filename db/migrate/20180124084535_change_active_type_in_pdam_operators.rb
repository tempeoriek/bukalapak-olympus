class ChangeActiveTypeInPdamOperators < ActiveRecord::Migration[5.1]
  def self.up
    change_column :pdam_operators, :active, :integer
  end

  def self.down
    change_column :pdam_operators, :active, :boolean
  end
end
