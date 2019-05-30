# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:pages) do
      add_full_text_index %i(title content description)
    end
  end
end
