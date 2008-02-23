class Permission < ActiveRecord::Base

  belongs_to :group
  belongs_to :user
  belongs_to :page

  def self.find_by_page(page)
    find(:all,
         :conditions => "page_id = #{page.id}",
         :include    => :user)
  end

  def self.find_global_by_page(page)
    find(:first, # There can be only one
         :conditions => "page_id = #{page.id} AND global != '0'")
  end

  def self.find_with_user_by_page(page)
    find(:all,
         :conditions => "page_id = #{page.id} AND user_id != '0'",
         :include    => :user,
         :order      => 'permissions.type')
  end

  def self.find_with_group_by_page(page)
    find(:all,
         :conditions => "page_id = #{page.id} AND group_id != '0'",
         :include    => :group,
         :order      => 'permissions.type')
  end

  def self.find_by_page_and_user(page, user)
    find(:first,
         :conditions => "page_id = #{page.id} AND user_id = #{user.id}",
         :include    => [ :page, :user ])
  end

  def self.find_by_page_and_group(page, group)
    find(:first,
         :conditions => "page_id = #{page.id} AND group_id = #{group.id}",
         :include    => [ :page, :group ])
  end

  def read_by?(user)
    return true if self.global?
    if not user.nil? and not user.guest?
      return true if user.admin?
      if self.user == user
        true
      else
        user.groups.include? self.group
      end
    end
  end

  def write_by?(user)
    return true if self.global? and self.is_a?(WritePermission)
    if not user.nil? and not user.guest?
      return true if user.admin?
      return false if not (self.is_a?(WritePermission) or self.is_a?(OwnPermission))
      if self.user == user
        true
      else
        user.groups.include? self.group
      end
    end
  end

  def own_by?(user)
    if not user.nil? and not user.guest?
      return false if not self.is_a?(OwnPermission)
      return true if user.admin?
      if self.user == user
        true
      else
        user.groups.include? self.group
      end
    end
  end

  def to_params
    self.id
  end

  def privilege
    self.class.to_s
  end

  protected

  def validate_on_create
    if self.page_id == 0
      errors.add(:page, 'Måste tillhöra en sida')
    end

    begin
      page = Page.find(self.page_id, :include => :permissions)
    rescue
      errors.add(:page, 'Gick inte att hitta sidan')
    end

    case # Make use global, group and user permissions don't colide
    when self.global?
      if self.user or self.group
        errors.add(:global, 'En global rättighet kan inte kombineras med andra')
      end

      if page.has_global_permission?
        errors.add(:global, 'Sidan har redan en global rättighet')
      end
    when self.user # User
      if self.global? or self.group
        errors.add(:user, 'Kan endast tillhöra en användare')
      end

      if Permission.find_by_page_and_user(self.page, self.user)
        errors.add(:user, 'Användaren har redan en rättighet för den här sidan')
      end
    when self.group # Group
      if self.global? or self.user
        errors.add(:group, 'Kan endast tillhöra en grupp')
      end

      if Permission.find_by_page_and_group(self.page, self.group)
        errors.add(:group, 'Gruppen har redan en rättighet för den här sidan')
      end
    end
  end

end
