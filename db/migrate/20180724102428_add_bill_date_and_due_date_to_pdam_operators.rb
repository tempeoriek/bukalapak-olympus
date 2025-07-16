class AddBillDateAndDueDateToPdamOperators < ActiveRecord::Migration[5.1]
  def change
    add_column :pdam_operators, :bill_day, :unsigned_tinyint
    add_column :pdam_operators, :due_day, :unsigned_tinyint
  end
end
