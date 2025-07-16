class CreateKeystore < ActiveRecord::Migration[5.1]
  def change
    create_table(:keystores, unsigned: true, options: 'DEFAULT CHARSET=utf8') do |t|
      t.string   :key
      t.string   :value
      t.datetime :expiration_time

      t.timestamps
    end

    add_index :keystores, :key
    add_index :keystores, :created_at
    add_index :keystores, :updated_at
  end
end
