Sequel.migration do
  change do
    alter_table(:countries) do
      add_column(:github, String)
    end
  end
end
