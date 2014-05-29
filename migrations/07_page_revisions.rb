Sequel.migration do
  change do
    alter_table(:pages) do
      add_column :revision, Integer, null: false, default: 1
    end

    create_table(:revisions) do
      primary_key :id
      foreign_key :page_id, :pages, null: false

      column :title, String
      column :content, String
      column :slug, String
      column :title_char, String
      column :compiled_content, String, text: true
      column :comment, String, text: true
      column :compiled_comment, String, text: true
      column :description, String, text: true
      column :compiled_description, String, text: true
      column :markup, String
      column :created_on, DateTime, null: false
      column :updated_on, DateTime, null: false
      column :revision, Integer, null: false
    end
  end
end
