# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:pages) do
      add_column :shorthand_title, String, unique: true
      add_column :title_char, String
      add_column :compiled_content, String, text: true
      add_column :comment, String, text: true
      add_column :compiled_comment, String, text: true
      add_column :description, String, text: true
      add_column :compiled_description, String, text: true
      add_column :markup, String
    end
  end
end
