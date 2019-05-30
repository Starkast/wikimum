# frozen_string_literal: true

Sequel.migration do
  up do
    alter_table(:pages) do
      add_column :created_on, DateTime, null: false, default: Time.now
      add_column :updated_on, DateTime, null: false, default: Time.now
    end
  end
  down do
    alter_table(:pages) do
      drop_column :created_on
      drop_column :updated_on
    end
  end
end
