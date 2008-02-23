class Group < ActiveRecord::Base

  has_many :permissions, :dependent => :destroy
  has_and_belongs_to_many :users
  belongs_to :creator, :class_name => 'User', :foreign_key => 'created_by'

  def has_member?(user)
    self.users.include? user
  end

  def self.find_by_name(name)
    Group.find(:first,
               :conditions => ['groups.name = ?', name],
               :include => ['users'])
  end

  def self.find_by_member(user)
    Group.find(:first,
               :conditions => ['users.id = ?', user.id],
               :include => ['users'])
  end

  def self.search_by_name(name)
    Group.find(:all,
              :conditions => ["name LIKE ?", '%' + name + '%'],
              :order => 'name ASC',
              :limit => 15)
  end

  def self.find_all
    Group.find(:all,
               :include => ['users'])
  end

  def to_param
    self.name
  end

  def to_s
    self.name
  end

  validates_presence_of   :name, :on => :create,
    :message => 'Du måste välja ett namn for gruppen'
  validates_uniqueness_of :name, :on => :create,
    :message => 'Gruppnamnet måste vara unikt'
  validates_length_of     :name, :on => :create, :within => 3..20,
    :too_long => 'Max 20 tecken i gruppnamnet', :too_short => 'Minst 3 tecken i gruppnamnet'
	validates_format_of     :name, :with   => /^[\d\wÅÄÖåäö_:-]*$/, 
		:on => :create, :message => 'Namnet får endast innehålla A-Ö, 0-9, _, - och :'

end
