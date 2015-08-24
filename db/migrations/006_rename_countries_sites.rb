Sequel.migration do
  change do
    rename_table :countries, :sites
  end
end
