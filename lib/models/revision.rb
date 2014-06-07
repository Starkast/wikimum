class Revision < Sequel::Model

  many_to_one :page
  many_to_one :author, class: :User

  def revisions
    self.page.revisions
  end

  def concealed
    self.page.concealed
  end
end
