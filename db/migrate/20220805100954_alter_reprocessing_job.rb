class AlterReprocessingJob < ActiveRecord::Migration[5.2]
  def up
    rename_column :reprocessing_jobs, :type, :job_type
  end

  def down
    rename_column :reprocessing_jobs, :job_type, :type
  end
end
