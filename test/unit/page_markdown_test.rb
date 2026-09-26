# frozen_string_literal: true

require "time"
require "yaml"

require_relative "../test_helper"
require_relative "../../lib/services/page_markdown"

class PageMarkdownTest < Minitest::Test
  FakePage = Struct.new(:title, :description, :revision, :updated_on, :content, keyword_init: true)

  def page(**attrs)
    FakePage.new(title: "Geekbench 5", revision: 3, content: "# Resultat\n", **attrs)
  end

  def front_matter(markdown)
    YAML.safe_load(markdown[/\A---\n.*?\n---\n/m])
  end

  def test_front_matter_precedes_content
    markdown = PageMarkdown.new(page).to_s

    assert_equal({ "title" => "Geekbench 5", "revision" => 3 }, front_matter(markdown))
    assert markdown.end_with?("---\n\n# Resultat\n")
  end

  def test_includes_description_and_update_time
    updated_on = Time.utc(2026, 9, 26, 12)
    markdown = PageMarkdown.new(page(description: "CPU-test", updated_on:)).to_s

    assert_equal "CPU-test", front_matter(markdown)["description"]
    assert_equal "2026-09-26T12:00:00Z", front_matter(markdown)["updated_on"]
  end

  def test_quotes_titles_that_would_break_yaml
    markdown = PageMarkdown.new(page(title: "Geekbench: 7")).to_s

    assert_equal "Geekbench: 7", front_matter(markdown)["title"]
  end

  def test_missing_content_renders_front_matter_only
    markdown = PageMarkdown.new(page(content: nil)).to_s

    assert markdown.end_with?("---\n\n")
  end
end
