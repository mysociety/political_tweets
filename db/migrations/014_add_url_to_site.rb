Sequel.migration do
  change do
    alter_table(:sites) do
      add_column :url, String
    end
  end
end
