class AddSieveActionLog < ActiveRecord::Migration[5.1]
  def change
    create_table(:sievex_action_logs, unsigned: true, options: 'DEFAULT CHARSET=utf8') do |t|
      t.bigint   :entity_id
      t.integer  :entity_type
      t.string   :actor
      t.string   :reason

      t.timestamps
    end

    add_index :sievex_action_logs, :entity_id
    add_index :sievex_action_logs, :created_at
    add_index :sievex_action_logs, :updated_at
  end
end
