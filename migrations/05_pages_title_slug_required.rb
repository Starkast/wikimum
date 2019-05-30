# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:pages) do
      set_column_not_null :title
      set_column_not_null :slug
      add_constraint(:title_not_empty, ~Sequel.like(:title, ''))
      add_constraint(:slug_not_empty, ~Sequel.like(:slug, ''))
    end
  end
  down do
    alter_table(:pages) do
      set_column_allow_null :title
      set_column_allow_null :slug
      drop_constraint(:title_not_empty)
      drop_constraint(:slug_not_empty)
    end
  end
end
