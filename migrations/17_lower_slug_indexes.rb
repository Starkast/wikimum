# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:pages) do
      add_index Sequel.function(:lower, :slug), name: :pages_lower_slug_index
    end

    alter_table(:revisions) do
      add_index [Sequel.function(:lower, :slug), :revision], name: :revisions_lower_slug_revision_index
    end
  end
end
