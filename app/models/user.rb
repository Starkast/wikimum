require 'digest/sha1'

class User < ActiveRecord::Base

  has_and_belongs_to_many :groups
  has_many :permissions, :dependent => :destroy

  before_save :compile
  after_validation :crypt_password
  after_save '@new_password = false'

  attr_accessor :new_password

  def initialize(attributes = nil)
    super
    @new_password = false
  end

  def member_of?(group)
    self.groups.include? group
  end

  def self.find_by_login(login, deleted = nil)
    # If deleted is nil, no deleted users should be found
    if deleted.nil?
      deleted = " AND users.type = ''"
    else
      deleted = ''
    end

    User.find(:first,
              :conditions => [ "login = ?" + deleted, login ],
              :include    => [ :permissions, :groups ])
  end
  
  def self.find_by_cookie_token(token)
    user = User.find(:first,
                     :conditions => [ "cookie_token = ?", token ])
    user if user and Time.now < user.cookie_expire 
  end

  def self.search_by_login(login)
    User.find(:all,
              :conditions => [ "login LIKE ? AND users.type = ''", '%' + login + '%' ],
              :order      => 'name ASC',
              :limit      => 15)
  end

  def self.find_all
    User.find(:all,
              :conditions => "users.type = ''",
              :include    => [ :permissions, :groups ])
  end

  def to_param
    self.login
  end

  def to_s
    self.name
  end

  def has_create_permission?
    self.admin? || WikiConf['permission']['create_page_for_all_users']
  end

  def guest?
    self.is_a?(Guest)
  end

  def deleted?
    self.is_a?(DeletedUser)
  end

  def real?
    self.is_a?(User) and not self.is_a?(Guest) and not self.is_a?(DeletedUser)
  end

  def number_of_created_pages
    Page.find(:all,
              :conditions => [ "created_by = ?", self.id ]).length
  end

  def number_of_changes
    condition = [ "updated_by = ?", self.id ]
    num       = Revision.find(:all, :conditions => condition).length
    num      += Page.find(:all, :conditions => condition).length
    return num
  end

  def attempt_login(ip)
    User.authenticate(self.login, self.password, ip)
  end

  def fake_destroy(user)
    # Don't delete yourself
    if self == user
      raise
    end

    # Remove all group memberships
    if not self.groups.empty?
      self.groups.each do |group|
        group.remove_users self
      end
    end

    # Remove all permissions
    if not self.permissions.empty?
      self.permissions.each do |permission|
        permission.destroy
      end
    end

    # Remove most of the information
    self.login = nil
    self.name  = 'en borttagen användare'
    self.email = nil
    self.markup = nil
    self.notes, self.compiled_notes = nil
    self.salt, self.hashed_password = nil
    self[:type] = 'DeletedUser'
    self.save_with_validation(false)
    true # This is a bit of a hack
  end

  def compile
    self.compiled_notes = Markup.to_html(self.notes, self.markup)
  end

  def self.authenticate(login, password, ip)
    u = User.find(:first,
                  :conditions => [ "login = ? AND users.type = ''", login ])
    
    return nil if u.nil?

    condition = [ "login = ? AND hashed_password = ?", login, salted_password(u.salt, hashed(password)) ]

    authenticated_user = User.find(:first,
                 :conditions => condition,
                 :include    => :groups)

    # Note the time and save the IP
    # If the user is connecting through proxies, use the originating IP
    # These are protected attributes, can't mass assign them, though
    # it might be a bit unnecissary to use update_attribute here ... XXX
    if authenticated_user
      authenticated_user.update_attribute(:last_login, Time.now)
      authenticated_user.update_attribute(:ip, ip.split(',').first)
      authenticated_user.update_attribute(:cookie_token, User.hashed("#{login}-#{Time.now.to_f.to_s}-cookie-token99"))
      authenticated_user.update_attribute(:cookie_expire, 1.year.from_now)
    end

    # Return the User-stuff, with or without an user
    authenticated_user
  end

  def change_password(password, confirm = nil)
    self.password = password
    self.password_confirmation = confirm.nil? ? password : confirm
    @new_password = true
  end

  protected

  # Lets us create a user with some nice instance variables that will be
  # used when we create or verify the user
  attr_accessor :password, :password_confirmation
  attr_accessible :login, :name, :email, :notes, :password, :password_confirmation, :ip, :markup

  def validate_password?
    @new_password
  end

  def self.hashed(string)
    Digest::SHA1.hexdigest("is-this-a-salt--#{string}--")
  end

  def self.salted_password(salt, hashed_password)
    hashed(salt + hashed_password)
  end


  def crypt_password
    if @new_password
      write_attribute('salt', User.hashed("salt-#{Time.now}"))
      write_attribute('hashed_password', User.salted_password(salt, User.hashed(@password)))
    end
  end

  def validate_on_create
    if User.find_by_login(login)
      errors.add(:login, 'Användarnamnet finns redan i systemet')
    end
  end

  validates_length_of :login, :on => :create, :within => 3..15,
    :too_short => 'Användarnamnet måste minst innehålla 3 tecken',
    :too_long => 'Användarnamnet får max vara 40 tecken långt'
  validates_format_of :login, :on => :create, :with => /^([-a-z0-9]+)$/i, 
    :message => 'Användarnamn får endast innehålla A-Z, 0-9 och -'
  validates_length_of :password, :on => :save, :within => 5..40, 
    :too_short => 'Minst 5 tecken i lösenordet', :too_long => 'Max 40 tecken i lösenordet',
    :if => Proc.new { |user| user.new_password }
  validates_presence_of :password, :on => :save, :message => 'Lösenord måste anges',
    :if => Proc.new { |user| user.new_password }
  validates_confirmation_of :password, :on => :save, :message => 'Lösenord måste verifieras',
    :if => Proc.new { |user| user.new_password }
  validates_format_of :email, :on => :save, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/,
    :message => 'Korrekt e-postadress tack'
  validates_presence_of :name, :on => :save, :message => 'Namn måste anges'

end
