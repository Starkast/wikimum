# frozen_string_literal: true

Sequel.migration do
  up do
    # SQLite is not using indexes for full text search
    # https://sqlite.org/fts5.html
    next if database_type == :sqlite

    alter_table(:pages) do
      add_full_text_index %i(title content description)
    end
  end

  down do
    next if database_type == :sqlite

    alter_table(:pages) do
      drop_index %i(title content description)
    end
  end
end
