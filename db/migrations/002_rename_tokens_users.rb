Sequel.migration do
  change do
    rename_table(:tokens, :users)
    alter_table(:users) do
      rename_column(:uid, :twitter_uid)
    end
  end
end
