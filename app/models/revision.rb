class Revision < ActiveRecord::Base

  belongs_to :updater, :class_name => 'User', :foreign_key => 'updated_by'
  belongs_to :creator, :class_name => 'User', :foreign_key => 'created_by'
  belongs_to :page

  def self.find_by_page(page, revision = nil)
    if not revision.nil?
      condition    = [ "page_id = ? AND revision = ?", page.attributes["id"], revision ]
      first_or_all = :first
    else
      condition    = [ "page_id = ?", page.attributes["id"] ]
      first_or_all = :all
    end

    Revision.find(first_or_all,
                  :conditions => condition,
                  :include    => 'updater',
                  :order      => 'revision DESC')
  end

  def self.find_by_title(title, revision = nil)
    if not revision.nil?
      condition    = [ "title = ? AND revision = ?", title, revision ]
      first_or_all = :first
    else
      condition    = [ "title = ?", title ]
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
