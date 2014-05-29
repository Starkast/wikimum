class User < Sequel::Model
  def before_save
    self.created_on ||= Time.now
    super
  end
end
