class User < ActiveRecord::Migration
  def self.up
    add_column :users, :markup, :string, :limit => 30
  end

  def self.down
    remove_column :users, :markup
  end
end
