class CreateSearchHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :search_histories do |t|
      # Simula o cliente logado do RN-C09: cabeçalho X-Client-Id.
      t.string :client_id, null: false
      t.jsonb :criteria, null: false, default: {}

      t.timestamps
    end

    add_index :search_histories, [ :client_id, :created_at ]
  end
end
