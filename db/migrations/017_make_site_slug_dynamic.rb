Sequel.migration do
  up do
    alter_table(:sites) do
      drop_column :slug
      add_column :country_slug, String
      add_column :legislature_slug, String
      add_unique_constraint [:country_slug, :legislature_slug]
    end
  end

  down do
    alter_table(:sites) do
      drop_column :country_slug
      drop_column :legislature_slug
      add_column :slug, String
      add_unique_constraint :slug
    end
  end
end
