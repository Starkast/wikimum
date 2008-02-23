class Revision < ActiveRecord::Base

  belongs_to :updater, :class_name => 'User', :foreign_key => 'updated_by'
  belongs_to :creator, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :page

  def self.find_by_title(title, revision = nil)
    if not revision.nil?
      condition    = [ "shorthand_title = ? AND revision = ?", title, revision ]
      first_or_all = :first
    else
      condition    = [ "shorthand_title = ?", title ]
      first_or_all = :all
    end

    Revision.find(first_or_all,
                  :conditions => condition,
                  :include    => 'updater',
                  :order      => 'revision DESC')
  end

  def to_param
    self.shorthand_title
  end

  def to_s
    self.title
  end

  # Alias
  def number
    revision
  end

  def previous
    revision - 1 unless revision <= 1
  end

  def first?
    revision == 1
  end

end
