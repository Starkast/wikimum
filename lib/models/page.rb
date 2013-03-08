class Page < Sequel::Model
  def before_create
    self.slug = self.title.gsub(/[^\w\s\d]/, '').gsub(' ', '_')
  end

  def before_save
    self.compiled_content = Markup.to_html(self.content, self.markup.to_sym)
  end
end