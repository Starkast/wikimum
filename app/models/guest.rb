class Guest < User

  def initialize(attributes = nil)
    super
    self.login = 'Gäst'
    self.name  = 'en gästanvändare'
  end

  attr_accessible :ip

  def has_create_permission?
    false
  end
end
