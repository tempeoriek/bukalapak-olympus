class CreateZakatNotifications < ActiveRecord::Migration[5.2]
  def self.up
    create_table :zakat_notifications do |t|
      t.bigint  :user_id, nullable: false, unsigned: true
      t.integer :day, limit: 1, default: 0
      t.boolean :active, default: true
      t.timestamps

      t.index  :day
      t.index  :user_id
    end
  end

  def self.down
    drop_table :zakat_notifications
  end
end
