# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:uploads) do
      primary_key :id
      foreign_key :page_id, :pages, null: false, on_delete: :cascade, index: true
      foreign_key :author_id, :users, null: true

      String :filename, null: false
      String :content_type, null: false
      File :data, null: false

      DateTime :created_on, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
