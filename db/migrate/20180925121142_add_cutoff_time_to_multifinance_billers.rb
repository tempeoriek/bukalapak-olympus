class AddCutoffTimeToMultifinanceBillers < ActiveRecord::Migration[5.1]
  def up
    add_column :multifinance_billers, :cutoff_start, :time
    add_column :multifinance_billers, :cutoff_end,   :time
  end

  def down
    remove_column :multifinance_billers, :cutoff_start
    remove_column :multifinance_billers, :cutoff_end
  end
end
