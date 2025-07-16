class CreateReprocessingJobs < ActiveRecord::Migration[5.2]
  def change
    create_table :reprocessing_jobs do |t|
      t.string :type
      t.datetime :stuck_transaction_date
      t.integer :state
      t.integer :triggered_by_user_id
      t.string :triggered_by_user_name

      t.timestamps
    end
    add_index :reprocessing_jobs, :state
  end
end
