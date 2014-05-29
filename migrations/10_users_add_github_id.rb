Sequel.migration do
  up do
    alter_table(:users) do
      add_column :github_id, Integer, null: false, unique: true
      set_column_allow_null :login
    end
  end
  down do
    alter_table(:users) do
      drop_column :github_id
      set_column_not_null :login
    end
  end
end
