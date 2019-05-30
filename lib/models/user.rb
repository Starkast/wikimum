# frozen_string_literal: true

class User < Sequel::Model

  one_to_many :pages
  one_to_many :revision

  def before_save
    self.created_on ||= Time.now
    super
  end

  def to_s
    self.login
  end
end
