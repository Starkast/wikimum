require 'redcarpet/compat'

# TODO
# * HTML support, just sanitize it

class Markup
  MARKUPS = { markdown: Markdown, textile: RedCloth }

  def self.markups
    MARKUPS.keys
  end

  def self.to_html(content, markup = :markdown)
    fail "Unknown markup" unless MARKUPS.include?(markup)
    MARKUPS[markup].new(content).to_html
  end
end