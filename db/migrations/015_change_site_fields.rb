Sequel.migration do
  change do
    alter_table(:sites) do
      rename_column :github, :github_organization
    end
  end
end
