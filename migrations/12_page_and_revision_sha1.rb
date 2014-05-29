require 'digest'

Sequel.migration do
  up do
    alter_table(:pages) do
      add_column :sha1, String
    end

    self[:pages].each do |page|
      sha1 = Digest::SHA1.hexdigest(page.values.join)
      self[:pages].where(id: page[:id]).update(sha1: sha1)
    end

    alter_table(:revisions) do
      add_column :sha1, String
    end

    self[:revisions].each do |revision|
      sha1 = Digest::SHA1.hexdigest(revision.values.join)
      self[:revisions].where(id: revision[:id]).update(sha1: sha1)
    end

  end

  down do
    alter_table(:pages) do
      drop_column :sha1
    end

    alter_table(:revisions) do
      drop_column :sha1
    end
  end
end
