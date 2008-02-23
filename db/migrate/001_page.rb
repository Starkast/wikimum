class Page < ActiveRecord::Migration
  def self.up
    add_column :pages, :markup, :string, :limit => 30
  end

  def self.down
    remove_column :pages, :markup
  end
end
