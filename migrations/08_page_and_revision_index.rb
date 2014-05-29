Sequel.migration do
  change do
    alter_table(:pages) do
      add_index [:title_char, :title]
    end
  end
end
