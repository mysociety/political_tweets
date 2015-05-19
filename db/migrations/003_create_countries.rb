Sequel.migration do
  up do
    create_table(:countries) do
      primary_key :id
      String :name, null: false
      String :url, null: false
      String :latest_term_csv, null: false
      foreign_key :user_id, :users, null: false, index: true
    end
    alter_table(:users) do
      drop_column(:country)
    end
  end

  down do
    drop_table(:countries)
    alter_table(:users) do
      add_column :country, String, null: false
    end
  end
end
