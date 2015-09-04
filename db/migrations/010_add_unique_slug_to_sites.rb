Sequel.migration do
  change do
    alter_table(:sites) do
      add_unique_constraint :slug
    end
  end
end
