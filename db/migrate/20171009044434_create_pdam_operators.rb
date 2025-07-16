class CreatePdamOperators < ActiveRecord::Migration[5.1]
  def change
    create_table :pdam_operators do |t|
      t.string :code
      t.string :name
      t.string :group
      t.string :image_url

      t.timestamps
    end
  end
end
