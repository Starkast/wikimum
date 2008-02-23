class Session < ActiveRecord::Migration
  def self.up
    add_column :sessions, :updated_at, :datetime
  end

  def self.down
    remove_column :sessions, :updated_at
  end
end
