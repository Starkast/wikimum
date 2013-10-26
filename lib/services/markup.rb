require 'redcarpet/compat'

# TODO
# * HTML support, just sanitize it
# * Just GitHub flavored Markdown

class Markup
  def self.to_html(content)
    Markdown.new(content).to_html
  end
end
