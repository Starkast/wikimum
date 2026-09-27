# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table(:users) do
      add_foreign_key :owner_id, :users, null: true, index: true
    end

    create_table(:bot_credentials) do
      primary_key :id
      foreign_key :bot_id, :users, null: false, unique: true
      foreign_key :page_id, :pages, null: false, on_delete: :cascade, index: true

      String :enrollment_digest
      DateTime :enrollment_expires_on
      String :secret_digest
      DateTime :enrolled_on
      DateTime :last_used_on
      DateTime :revoked_on
      DateTime :created_on, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
