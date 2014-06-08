Sequel.migration do
  change do
    add_column :pages, :concealed, TrueClass
  end
end
