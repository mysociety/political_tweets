Sequel.migration do
  change do
    alter_table(:sites) do
      rename_column :url, :slug
    end
  end
end
