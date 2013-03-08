class Page < Sequel::Model
  def before_save
    markdown = Markup::MARKUPS[self.markup.to_sym]

    self.compiled_content = Markup.to_html(self.content, markup)
  end
end