# frozen_string_literal: true

require "yaml"

class PageMarkdown
  def self.list(heading, pages)
    items = pages.map do |page|
      title = page.title.gsub(/[\[\]]/) { "\\#{_1}" }
      description = page.description.to_s.split.join(" ")
      item = "- [#{title}](/#{page.slug_for_uri}.md)"
      description.empty? ? item : "#{item}: #{description}"
    end

    "# #{heading}\n\n#{items.map { "#{_1}\n" }.join}"
  end

  def initialize(page)
    @page = page
  end

  def to_s
    "#{front_matter}---\n\n#{@page.content}"
  end

  private

  def front_matter
    {
      "title" => @page.title,
      "description" => @page.description,
      "revision" => @page.revision,
      "updated_on" => @page.updated_on&.iso8601,
    }.compact.to_yaml
  end
end
