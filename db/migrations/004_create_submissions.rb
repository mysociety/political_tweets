Sequel.migration do
  change do
    create_table(:submissions) do
      primary_key :id
      String :twitter, null: false
      Integer :person_id, null: false
      foreign_key :country_id, :countries, null: false, index: true
    end
  end
end
