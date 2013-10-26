Sequel.migration do
	change do
		create_table(:pages) do
			primary_key :id
			String :title
			Text :content
		end
	end
end