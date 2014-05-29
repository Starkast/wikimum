class Revision < Sequel::Model

  many_to_one :page

  def revisions
    self.page.revisions
  end

end
