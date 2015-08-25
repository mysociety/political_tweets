Sequel.migration do
  change do
    alter_table(:submissions) do
      rename_column :country_id, :site_id
    end
  end
end
