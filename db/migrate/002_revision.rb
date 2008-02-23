class Revision < ActiveRecord::Migration
  def self.up
    add_column :revisions, :markup, :string, :limit => 30
  end

  def self.down
    remove_column :revisions, :markup
  end
end
