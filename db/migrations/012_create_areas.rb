Sequel.migration do
  change do
    create_table(:areas) do
      primary_key :id
      String :name, null: false
      String :ocd_id
      Integer :twitter_list_id
      String :twitter_list_slug
      foreign_key :site_id, :sites, null: false, index: true
      unique [:site_id, :name]
    end
  end
end
