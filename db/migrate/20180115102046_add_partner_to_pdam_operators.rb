class AddPartnerToPdamOperators < ActiveRecord::Migration[5.1]
  def change
    add_column :pdam_operators, :partner, :integer, :default => 0
  end
end
