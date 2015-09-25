Sequel.migration do
  change do
    alter_table(:submissions) do
      add_column :status, String, default: 'pending'
    end
  end
end
