Sequel.migration do
  change do
    alter_table(:pages) do
      add_foreign_key :author_id, :users, null: false
    end

    alter_table(:revisions) do
      add_foreign_key :author_id, :users, null: false
    end

    alter_table(:users) do
      # We're not able to map all old users to GitHub users
      set_column_allow_null :github_id
    end
  end
end
