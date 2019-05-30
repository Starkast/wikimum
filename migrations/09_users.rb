# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:users) do
      drop_column :type
      drop_column :ip
      drop_column :hashed_password
      drop_column :salt
      drop_column :name
      drop_column :admin
      drop_column :company
      drop_column :created_by
      drop_column :notes
      drop_column :compiled_notes
      drop_column :lock_version
      drop_column :markup
      set_column_allow_null :email
    end
  end
  down do
    alter_table(:users) do
      add_column :type,            String, null: false
      add_column :ip,              String, null: false
      add_column :hashed_password, String, null: false
      add_column :salt,            String, null: false
      add_column :name,            String, null: false
      add_column :admin,           String, null: false
      add_column :company,         String
      add_column :created_by,      String, null: false
      add_column :notes,           String
      add_column :compiled_notes,  String
      add_column :lock_version,    String
      add_column :markup,          String
      set_column_not_null :email
    end
  end
end
