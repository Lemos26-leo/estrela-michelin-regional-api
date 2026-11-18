class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      # cuisine, occasion, vibe, amenity
      t.integer :category, null: false

      t.timestamps
    end

    add_index :tags, [ :category, :name ], unique: true
  end
end
