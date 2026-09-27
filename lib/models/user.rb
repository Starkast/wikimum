# frozen_string_literal: true

class User < Sequel::Model

  one_to_many :pages
  one_to_many :revision
  many_to_one :owner, class: :User

  def before_save
    self.created_on ||= Time.now
    super
  end

  def to_s
    owner ? "#{login} (via #{owner.login})" : login
  end
end
