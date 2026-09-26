# frozen_string_literal: true

require "yaml"

class PageMarkdown
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
