Sequel.migration do
  change do
    alter_table(:submissions) do
      add_column :name, String
    end
  end
end
