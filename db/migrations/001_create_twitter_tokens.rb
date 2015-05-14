Sequel.migration do
  change do
    create_table(:tokens) do
      primary_key :id
      String :uid, null: false
      String :token, null: false
      String :secret, null: false
      String :country, null: false
    end
  end
end
