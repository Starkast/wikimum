class User < Sequel::Model

  one_to_many :pages
  one_to_many :revision

  def before_save
    self.created_on ||= Time.now
    super
  end
end
