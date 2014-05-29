Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String      :type,            null: false
      String      :ip,              null: false
      String      :login,           null: false
      String      :hashed_password, null: false
      String      :salt,            null: false
      String      :name,            null: false
      TrueClass   :admin,           null: false
      String      :email,           null: false
      String      :company
      DateTime    :created_on,      null: false
      String      :created_by,      null: false
      DateTime    :last_login
      String      :notes
      String      :compiled_notes
      Integer     :lock_version
      String      :markup
    end
  end
end
