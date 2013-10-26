require 'redcarpet/compat'

# TODO
# * HTML support, just sanitize it
# * Just GitHub flavored Markdown

class Markup
  def self.to_html(content)
    wikified_content = self.wikify_content(content)
    Markdown.new(wikified_content).to_html
  end

  # Snatched from old Wikimum codebase
  def self.wikify_content(content)
    content.gsub(/\[\[([\d\w\sÅÄÖåäö_:-]{1,35})\]\]/i) do
      "[#{$1}](/#{$1})"
    end
  end
end
