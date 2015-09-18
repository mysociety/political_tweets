Sequel.migration do
  change do
    alter_table(:sites) do
      add_column :twitter_all_list_id, Integer
      add_column :twitter_all_list_slug, String
    end
  end
end
