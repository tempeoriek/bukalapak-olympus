class CreateZakatFoundations < ActiveRecord::Migration[5.2]
  def self.up
    create_table :zakat_foundations do |t|
      t.string    :name, nullable: false
      t.text      :description
      t.boolean   :active, default: true
      t.timestamp :deactivated_at
      t.string    :image_url
      t.string    :available_types
      t.bigint    :wallet_user_id, default: 0, nullable: false
      t.datetime  :fitrah_end_date, default: '2019-05-01 00:00:00', nullable: false
      t.integer   :sort_order, default: 99, nullable: false
      t.decimal   :revenue_percentage, precision: 5, scale: 2, default: '0.0'

      t.timestamps

      t.index :active
    end
  end

  def self.down
    drop_table :zakat_foundations
  end
end
