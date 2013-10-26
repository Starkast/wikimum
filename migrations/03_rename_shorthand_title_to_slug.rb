Sequel.migration do
  change do
    alter_table(:pages) do
      rename_column :shorthand_title, :slug
    end
  end
end